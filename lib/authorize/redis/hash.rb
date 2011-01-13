module Authorize
  module Redis
    class Hash < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def get(k)
        self.class.db.hget(id, k)
      end

      def set(k, v)
        self.class.db.hset(id, k, v)
      end

      def merge(h)
        args = h.inject([]) do |m,(k,v)|
          m << k
          m << v
        end
        self.class.db.hmset(id, *args)
      end

      def __getobj__
        self.class.db.hgetall(id)
      end
    end
  end
end