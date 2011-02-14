module Authorize
  module Redis
    class Array < Base
      def [](index)
        db.lrange(id, index, index)
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
    end
  end
end