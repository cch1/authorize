module Authorize
  module Redis
    # Persist Ruby objects to Redis DB using natural type affinity
    module Fixtures
      def create_fixtures(db, pathname, flush = true)
        db.flushdb if flush
        fixtures = YAML.load(ERB.new(pathname.read).result)
        fixtures.each do |node|
          node.each_pair do |key, value|
            case value
              when ::Hash then value.each_pair {|k, v| db.hset(key, k, v)}
              when ::Set then value.each {|v| db.sadd(key, v)}
              when ::Array then value.each {|v| db.rpush(key, v)}
              else db.set(key, value) # String, Fixnum, NilClass
            end
          end
        end
      end
      module_function :create_fixtures
    end
  end
end