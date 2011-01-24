require 'monitor'
require 'set'
require 'forwardable'

module Authorize
  # Arbitrate thread-safe access to a limited set of expensive and perishable objects
  class ResourcePool
    extend Forwardable

    def_delegators :@pool, :include?
    def_delegators :@tokens, :empty?

    attr_reader :num_waiting

    # Create a new unfilled resource pool with a capacity of of at most max_size objects.  The pool
    # is lazily filled by the factory lambda.
    def initialize(max_size, factory)
      @factory = factory
      @pool = []
      @tokens = []
      @monitor = Monitor.new
      @tokens_cv = @monitor.new_cond
      @num_waiting = 0
      max_size.times {|i| @tokens.unshift(i)}
    end

    def size
      @pool.compact.length
    end

    def available
      @tokens.size
    end

    # Checkout an object from the pool.  Arguments are passed unmolested to ConditionVariable#wait to manage timeouts.
    def checkout(*args)
      @monitor.synchronize do
        until token = @tokens.pop
          begin
            @num_waiting += 1
            raise "Timed out during checkout" unless @tokens_cv.wait(*args)
          ensure
            @num_waiting -= 1
          end
        end
        @pool[token] ||= @factory.call
      end
    end

    # Return an object to the pool
    def checkin(obj)
      @monitor.synchronize do
        token = @pool.index(obj)
        raise "#{obj} has not been checked out from this pool" unless token && !@tokens.include?(token)
        @tokens.push(token) if token
        @tokens_cv.signal
      end
    end

    # Expire resources in inventory with the given block.  Available (not reserved) pool members are
    # yielded to the block.  The object is expired (removed permanently from the pool) if the block
    # returns a true-ish value.
    def expire
      @monitor.synchronize do
        @tokens.each do |i|
          next unless obj = @pool[i]
          @pool[i] = nil if yield obj
        end
      end
    end

    # Freshen objects in inventory with the given block
    def freshen
      expire {|obj| yield(obj) ; return false}
    end

    # Remove all resources from the pool and revoke all tokens
    # TODO: don't brutally/blindly revoke tokens -raise an exception or fire a callback, and address waiting threads.
    def clear!
      @monitor.synchronize do
        @pool.each_index {|i| @tokens << i}
        @tokens.uniq!
        @pool.clear
      end
    end
  end
end