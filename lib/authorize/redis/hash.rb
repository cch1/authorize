module Authorize
  module Redis
    class Hash < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def get(k)
        db.hget(id, k)
      end

      def set(k, v)
        db.hset(id, k, v)
      end

      def merge(h)
        args = h.inject([]) do |m,(k,v)|
          m << k
          m << v
        end
        db.hmset(id, *args)
      end

      def __getobj__
        db.hgetall(id)
      end

      def ==(other)
        eql?(other) || (__getobj__ == other.__getobj__)
      end
    end
  end
end