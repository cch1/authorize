module Authorize
  module Redis
    class String < Base
      def __getobj__
        db.get(id)
      end

      def set(v)
        db.set(id, v)
      end

      def ==(other)
        eql?(other) || (__getobj__ == other.__getobj__)
      end
    end
  end
end