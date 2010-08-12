module Authorize
  module Redis
    # Persist Ruby objects to Redis DB using natural type affinity
    module Fixtures
      def redis_fixtures(db, pathname)
        db.flushdb
        fixture_dictionary = YAML.load(ERB.new(pathname.read).result)
        fixture_dictionary.each_pair do |key, value|
          case value
            when ::Hash then value.each_pair {|k, v| db.hset(key, Marshal.dump(k), Marshal.dump(v))}
            when ::Set then value.each {|v| db.sadd(key, Marshal.dump(v))}
            when ::Array then value.each {|v| db.rpush(key, Marshal.dump(v))}
            else db.set(key, Marshal.dump(value)) # String, Fixnum, NilClass
          end
        end
      end
    end
  end
end