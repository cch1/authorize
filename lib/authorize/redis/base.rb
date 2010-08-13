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
        index[id] = allocate.tap do |o|
          o.instance_variable_set(:@id, id)
          o.send(:initialize, *args, &block)
        end
      end

      def self.load(id)
        index[id] ||= allocate.tap do |o|
          o.instance_variable_set(:@id, id)
          o.send(:reload)
        end
      end
      def self._load(id);load(id);end

      attr_reader :id
      alias to_s id

      def eql?(other)
        other.is_a?(self.class) && id.eql?(other.id)
      end

      def hash
        id.hash
      end

      def ==(other)
        __getobj__ == other.__getobj__
      end

      def subordinate_key(name, counter = false)
        k = [id, name].join(':')
        counter ? [k, self.class.counter(k)].join(':') : k
      end

      # This hook restores a re-instantianted object that has previously been initialized and then persisted.
      # Non-idempotent operations should be used with great care.
      def reload;end

      def _dump(depth = nil)
        id
      end

      # Methods that don't change the state of the object can safely delegate to a Ruby proxy object
      def __getobj__
        raise "Abstract class requires implementation"
      end

      def method_missing(m, *args, &block)
        proxy = __getobj__ # Performance tweak
        return super unless proxy.respond_to?(m) # If there is going to be an explosion, let superclass handle it.
        proxy.freeze.__send__(m, *args, &block) # Ensure no state can be changed and send the method on its way.
      end

      def respond_to?(m, include_private = false)
        return true if super
        __getobj__.respond_to?(m, include_private)
      end
    end

    class Value < Base
      def __getobj__
        Marshal.load(self.class.db.get(id))
      end

      def set(v)
        self.class.db.set(id, Marshal.dump(v))
      end
    end

    class Set < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def add(v)
        self.class.db.sadd(id, Marshal.dump(v))
      end
      alias << add

      def delete(v)
        self.class.db.sdelete(id, Marshal.dump(v))
      end

      def __getobj__
        self.class.db.smembers(id).map{|s| Marshal.load(s)}.to_set
      end
    end

    class Hash < Base
      undef to_a # In older versions of Ruby, Object#to_a is invoked and #method_missing is never called.

      def get(k)
        Marshal.load(self.class.db.hget(id, Marshal.dump(k)))
      end

      def set(k, v)
        self.class.db.hset(id, Marshal.dump(k), Marshal.dump(v))
      end

      def merge(h)
        args = h.inject([]) do |m,(k,v)|
          m << Marshal.dump(k)
          m << Marshal.dump(v)
        end
        self.class.db.hmset(id, *args)
      end

      def __getobj__
        self.class.db.hgetall(id).inject({}) do |m, (k,v)|
          m[Marshal.load(k)] = Marshal.load(v)
          m
        end
      end
    end
  end
end