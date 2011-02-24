module Authorize
  module Redis
    class Set < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def valid?
        %w(none set).include?(db.type(id))
      end

      def add(v)
        db.sadd(id, v)
      end

      def <<(v)
        add(v)
      end

      def delete(v)
        db.srem(id, v)
      end

      def include?(v)
        db.sismember(id, v)
      end
      alias member? include?

      def sample(n = 1)
        return method_missing(:sample, n) unless n == 1
        db.srandmember(id)
      end

      def first(n = 1)
        return method_missing(:first, n) unless n == 1
        sample(n)
      end

      def __getobj__
        db.smembers(id).to_set
      end
    end
  end
end