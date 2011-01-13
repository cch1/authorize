module Authorize
  module Redis
    class String < Base
      def __getobj__
        self.class.db.get(id)
      end

      def set(v)
        self.class.db.set(id, v)
      end
    end
  end
end