module Authorize
  module Redis
    class Set < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def add(v)
        db.sadd(id, v)
      end
      alias << add

      def delete(v)
        db.srem(id, v)
      end

      def __getobj__
        db.smembers(id).to_set
      end
    end
  end
end