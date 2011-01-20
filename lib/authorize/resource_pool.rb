require 'thread'
require 'set'
require 'forwardable'

module Authorize
  # Arbitrate access to a limited set of expensive and perishable objects
  class ResourcePool
    extend Forwardable

    def_delegators :@reserved, :size
    def_delegators :@pool, :include?
    def_delegators :@token_q, :num_waiting, :empty?

    # Create a new unfilled resource pool with a capacity of of at most max_size objects.  The pool
    # is lazily filled by the factory lambda.
    def initialize(max_size, factory)
      @factory = factory
      @pool = []
      @reserved = Set.new
      @token_q = Queue.new
      max_size.times {|i| @token_q << i}
    end

    def num_available
      @token_q.length
    end

    # Checkout an object from the pool
    def checkout
      index = @token_q.pop(false)
      @reserved << index
      @pool[index] ||= @factory.call
    end

    # Return an object to the pool
    def checkin(obj)
      index = @pool.index(obj)
      raise "#{obj} has not been checked out from this pool" unless @reserved.delete?(index)
      @token_q.push(index) if index
    end

    # Expire objects in the pool with the given block.  Pool members are yielded to the block
    # along with an indicator of whether they are checked out.  The object is expired (removed
    # permanently from the pool) if the block returns a true-ish value.
    def expire
      @pool.each_with_index do |obj, i|
        next unless obj
        expired = yield obj, @reserved.member?(i)
        @pool[i] = nil if expired
      end
    end

    # Freshen objects in inventory with the given block
    def freshen
      expire {|obj, reserved| yield(obj) unless reserved ; return false}
    end
  end
end