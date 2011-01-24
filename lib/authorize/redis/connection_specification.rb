module Authorize
  module Redis
    class ConnectionSpecification
      attr_reader :db_spec

      def initialize(db_spec)
        @db_spec = db_spec
      end

      # Factory method returning a new connection to the database conforming to the specification
      def connect!
        ::Redis.new(db_spec)
      end
    end
  end
end