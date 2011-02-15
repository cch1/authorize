module Authorize
  module Redis
    class Hash < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def get(k)
        db.hget(id, k)
      end
      alias [] get

      def set(k, v)
        db.hset(id, k, v)
      end
      alias []= set

      def merge(h)
        return self if h.empty?
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