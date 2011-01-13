module Authorize
  module Redis
    class String < Base
      def __getobj__
        db.get(id)
      end

      def set(v)
        db.set(id, v)
      end
    end
  end
end