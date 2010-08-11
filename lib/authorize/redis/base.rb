require 'enumerator'

module Authorize
  module Redis
    # The key feature of this class is that it presents a coherent view of the database in memory.  For
    # each database entry, at most one in-memory Ruby object will exist, and all state for the object will
    # be atomically persisted to the database.  This behavior introduces the following constraints:
    #   1.  The database key must be known prior to initialization, allowing new objects to be instantiated
    #       only if no previously instantiated object with that key is already in memory.
    #   2.  In order to allow Redis#initialize to set values (which are atomically persisted), the id must
    #       be available at the _start_ of initialization.  This is accomplished by overriding Redis.new and
    #       assigning the id immediately after allocation.
    # TODO: YAML serialization (http://groups.google.com/group/comp.lang.ruby/browse_thread/thread/c855253c9d8f482e)
    class Base
      @base = true
      class << self
        attr_writer :db
        def db
          @db || (@base ? nil : superclass.db) # Search up the inheritance chain for a value, but allow overriding
        end
      end

      def self.counter(key)
        db.incr(key)
      end

      def self.build_id
        [name, counter(name)].join(':')
      end

      def self.index
        @index ||= ::Hash.new
      end

      def self.exists?(id)
        db.exists(id)
      end

      def self.new(id = nil, *args, &block)
        id ||= build_id
        index[id] ||= allocate.tap do |o|
          o.instance_variable_set(:@id, id)
          if exists?(id)
            o.send(:reloaded)
          else
            o.send(:initialize, *args, &block)
          end
        end
      end

      def self._load(id)
        index[id] || allocate.tap do |o|
          o.instance_variable_set(:@id, id)
          o.send(:reloaded)
        end
      end

      attr_reader :id

      # This hook accomodates re-initializing a previously initialized object that has been persisted.
      # It is good practice to limit re-initialization to idempotent operations.
      def reloaded;end

      def _dump(depth)
        id
      end

      def subordinate_key(name, counter = false)
        k = [id, name].join(':')
        counter ? [k, self.class.counter(k)].join(':') : k
      end
    end

    class Value < Base
      def get
        Marshal.load(self.class.db.get(id))
      end

      def set(v)
        self.class.db.set(id, Marshal.dump(v))
      end
    end

    class Set < Base
      include Enumerable

      def add(v)
        self.class.db.sadd(id, Marshal.dump(v))
      end
      alias << add

      def delete(v)
        self.class.db.sdelete(id, Marshal.dump(v))
      end

      def members
        self.class.db.smembers(id).map{|s| Marshal.load(s)}
      end

      def each(&block)
        members.each(&block)
      end

      def empty?
        members.empty?
      end

      def size
        members.size
      end
      alias length size
    end

    class Hash < Base
      def get(k)
        Marshal.load(self.class.db.hget(id, k))
      end

      def set(k, v)
        self.class.db.hset(id, k, Marshal.dump(v))
      end

      def merge(h)
        args = h.inject([]) do |m,(k,v)|
          m << k
          m << Marshal.dump(v)
        end
        self.class.db.hmset(id, *args)
      end

      def to_hash
        self.class.db.hgetall(id).inject({}) do |m, (k,v)|
          m[k] = Marshal.load(v)
          m
        end
      end
    end
  end
end