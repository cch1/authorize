require 'monitor'
require 'set'

module Authorize
  module Redis
    # This class arbitrates access to a Redis server ensuring that threads don't concurrently access the same connection
    # http://yehudakatz.com/2010/08/14/threads-in-ruby-enough-already/
    # http://blog.headius.com/2008/08/qa-what-thread-safe-rails-means.html
    # Inspired by the ConnectionPool class in Rails 2.3
    # Notes on thread-safety: Because instances of this class are expected to be shared
    # across threads, access to all non-local variables and "constants" need to be synchronized.
    # We assume that Hash read/assign operations are thread-safe.  We also require that the
    # value returned by #current_connection_id not be shared across threads.
    class ConnectionManager
      class ConnectionError < RuntimeError; end

      attr_reader :pool

      # Creates a new ConnectionPool object. +specification+ is a ConnectionSpecification
      # object which describes database connection parameters
      def initialize(specification, options = {})
        @options = {:size => 5}.merge(options)
        @pool = ResourcePool.new(@options[:size], lambda {specification.connect!})
        @connection_map = {} # Connections mapped to threads
        @mutex = Monitor.new
      end

      # Retrieve the connection associated with the current thread, or checkout one from the pool as required.
      # #connection can be called any number of times; the connection is held in a hash with a thread-specific key.
      def acquire_connection
        @connection_map[current_connection_id] ||= @pool.checkout(10)
      end
      alias connection acquire_connection

      # Signal that the thread is finished with the current connection.
      # #release_connection releases the connection-thread association
      # and returns the connection to the pool.
      def release_connection
        c = @connection_map.delete(current_connection_id)
        @pool.checkin(c) if c
      end

      # Checks out a connection from the pool, yields it to a block and checks it back into the pool when the block finishes.
      def with_connection
        c = @pool.checkout
        yield c
      ensure
        @pool.checkin(c)
      end

      # Identifies connections in the death grip of defunct threads, removes them from the map and checks them back into the pool
      # Because this method operates across connections for multiple threads (not just the current thread), concurrent execution
      # needs to be synchronized to be thread-safe.
      def recover_unused_connections
        tids = Thread.list.select{|t| t.alive?}.map(&:object_id)
        @mutex.synchronize do
          cids = @connection_map.keys
          (cids - tids).each do |sid|
            c = @connection_map.delete(sid)
            @pool.checkin(c)
          end
        end
      end

      # Expire stale connections
      def expire_stale_connections!
        @pool.expire do |connection, reserved_flag|
          !connection.client.connected?
        end
      end

      # Revert to a freshly initialized state
      def reset!
        @mutex.synchronize do
          @pool.clear!
          @connection_map.clear
        end
        self
      end

      private
      # In order to guarantee thread-safety, this value must never be shared across threads.
      def current_connection_id #:nodoc:
        Thread.current.object_id
      end
    end
  end
end