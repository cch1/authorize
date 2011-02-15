module Authorize
  module Redis
    # The key feature of this module is that it presents a coherent view of the database in memory.  For
    # each database entry, at most one in-memory Ruby object will exist, and all state for the object will
    # be atomically persisted to the database.  This behavior introduces the following constraints:
    #   1.  The database is viewed through an identity map (http://en.wikipedia.org/wiki/Identity_map) to
    #       ensure in-thread coherency.  Consequently, the record's key must be known prior to initialization,
    #       allowing new objects to be instantiated only if no previously instantiated object with that key is
    #       already in memory.
    #   2.  In order to allow Redis::Base#initialize to set values (which are atomically persisted), the id must
    #       be available at the _start_ of initialization.  This is accomplished by overriding Redis.new and
    #       assigning the id immediately after allocation.
    # TODO: YAML serialization (http://groups.google.com/group/comp.lang.ruby/browse_thread/thread/c855253c9d8f482e)
    class Base
      NAMESPACE_SEPARATOR = '::'
      @base = true
      class << self
        attr_writer :logger
        attr_writer :connection_specification

        # Should this class establish a connection instead of relying on a superclass' connection?
        def connection_base?
          @base || @connection_specification
        end

        # Search up the inheritance chain for a manager unless a connection is specified here.
        def connection_manager
          @manager ||= (connection_base? ? Authorize::Redis::ConnectionManager.new(@connection_specification) : superclass.connection_manager)
        end

        def connection
          connection_manager.connection
        end
        alias db connection
      end

      def self.logger
        @logger ||= (@base ? nil : superclass.logger)
      end

      def self.subordinate_key(*keys)
        keys.join(NAMESPACE_SEPARATOR)
      end

      def self.counter(key)
        db.incr(key)
      end

      def self.build_id
        subordinate_key(name, counter(name))
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

      def logger
        self.class.logger
      end

      def db
        self.class.db
      end

      def eql?(other)
        other.is_a?(self.class) && id.eql?(other.id)
      end

      def hash
        id.hash
      end

      def ==(other)
        __getobj__ == other.__getobj__
      end

      # Note that requesting a counter value "steals" from the class counter.
      def subordinate_key(name, counter = false)
        k = self.class.subordinate_key(id, name)
        counter ? self.class.subordinate_key(k, self.class.counter(k)) : k
      end

      # This hook restores a re-instantiated object that has previously been initialized and then persisted.
      # Non-idempotent operations should be used with great care.
      def reload;end

      def _dump(depth = nil)
        id
      end

      # Emit this Redis object with a a magic type and simple scalar identifier.  The (poorly documented) "type id" format
      # allows for a succinct one-line YAML expression for a Redis instance (no indented attributes hash required) which in
      # turn simplifies automatic YAMLification of collections of Redis objects.  Arguably, it's more readable as well.
      def to_yaml(opts = {})
        YAML.quick_emit(self.id, opts) {|out| out.scalar("tag:hapgoods.com,2010-08-11:#{self.class.name}", id)}
      end

      def destroy
        db.del(id) # This operation will remove all native Redis types (String, Hash, List, Set, etc.) in one shot.
        self.class.index.delete(id)
        freeze
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
  end
end

YAML.add_domain_type("hapgoods.com,2010-08-11", "") do |type, val|
  md = /tag:(.*),([^:]*):((?:\w+)(?:::\w+)*)/.match(type)
  domain, version, klass = *md[1..3]
  klass.constantize.load(val)
end