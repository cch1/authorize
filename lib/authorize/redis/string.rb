module Authorize
  module Redis
    class String < Base
      def valid?
        %w(none string).include?(db.type(id))
      end

      def __getobj__
        db.get(id)
      end

      def set(v)
        db.set(id, v)
      end
    end
  end
end