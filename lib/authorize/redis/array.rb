module Authorize
  module Redis
    class Array < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def valid?
        %w(none list).include?(db.type(id))
      end

      def [](index)
        if index.respond_to?(:first)
          db.lrange(id, index.first, index.last)
        else
          db.lindex(id, index)
        end
      end

      def []=(index, v)
        db.lset(id, index, v)
      end

      def push(v)
        db.rpush(id, v)
      end
      alias << push

      def pop
        db.rpop(id)
      end

      def __getobj__
        db.lrange(id, 0, -1)
      end

      def ==(other)
        eql?(other) || (__getobj__ == other.__getobj__)
      end
    end
  end
end