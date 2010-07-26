require 'enumerator'

module Authorize
  # The key feature of this class is that it presents a coherent view of the database in memory.  For
  # each database entry, at most one in-memory Ruby object will exist, and all state for the object will
  # be atomically persisted to the database.  This behavior introduces the following constraints:
  #   1.  The database key must be known prior to initialization, allowing new objects to be instantiated
  #       only if no previously instantiated object with that key is already in memory.
  #   2.  In order to allow Redis#initialize to set values (which are atomically persisted), the id must
  #       be available at the _start_ of initialization.  This is accomplished by overriding Redis.new and
  #       assigning the id immediately after allocation.
  class Redis
    class << self
      attr_accessor :db
    end

    def self.counter(key)
      Authorize::Redis.db.incr(key)
    end

    def self.build_id
      [name, counter(name)].join(':')
    end

    def self.index
      @index ||= ::Hash.new
    end

    def self.exists?(id)
      Authorize::Redis.db.exists(id)
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

  class Value < Redis
    def get
      Marshal.load(Authorize::Redis.db.get(id))
    end

    def set(v)
      Authorize::Redis.db.set(id, Marshal.dump(v))
    end
  end

  class Set < Redis
    include Enumerable

    def add(v)
      Authorize::Redis.db.sadd(id, Marshal.dump(v))
    end
    alias << add

    def delete(v)
      Authorize::Redis.db.sdelete(id, Marshal.dump(v))
    end

    def members
      Authorize::Redis.db.smembers(id).map{|s| Marshal.load(s)}
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

  class Hash < Authorize::Redis
    def get(k)
      Marshal.load(Authorize::Redis.db.hget(id, k))
    end

    def set(k, v)
      Authorize::Redis.db.hset(id, k, Marshal.dump(v))
    end

    def merge(h)
      args = h.inject([]) do |m,(k,v)|
        m << k
        m << Marshal.dump(v)
      end
      Authorize::Redis.db.hmset(id, *args)
    end

    def to_hash
      Authorize::Redis.db.hgetall(id).inject({}) do |m, (k,v)|
        m[k] = Marshal.load(v)
        m
      end
    end
  end

  # A binary property graph.  Vertices and Edges have an arbitrary set of named properties.
  # Reference: http://www.nist.gov/dads/HTML/graph.html
  class Graph < Authorize::Redis
    class Vertex < Authorize::Hash
      # Because a degenerate vertex can have neither properties nor edges, we must store a marker to indicate existence
      def self.exists?(id)
        super([id, 'marker'].join(':'))
      end

      def initialize(properties = {})
        Authorize::Redis.db.multi do
          super()
          Value.new(subordinate_key('marker')).set(nil)
          merge(properties) if properties.any?
        end
      end

      def edges
        @edges ||= Set.new(subordinate_key('edges'))
      end

      def neighbors
        edges.map{|e| e.right}
      end

      def to_s
        get(:name) || "Unnamed"
      end
    end

    # An edge connects two vertices.  The edge is directed from left to right only (unidirectional), but references are
    # available in both directions.
    # TODO: a hyperedge can be modeled with a set of vertices instead of explicit left and right vertices.
    class Edge < Authorize::Hash
      # Because a degenerate edge may have no properties and only left and right vertices, we need to adjust our definition of existence
      def self.exists?(id)
        super([id, 'l'].join(':'))
      end

      def initialize(v0, v1, properties = {})
        Authorize::Redis.db.multi do
          super()
          Value.new(subordinate_key('l')).set(v0)
          Value.new(subordinate_key('r')).set(v1)
          v0.edges << self
          merge(properties) if properties.any?
        end
        @l, @r = v0, v1
      end

      def left
        @l ||= Value.new(subordinate_key('l')).get
      end

      def right
        @r ||= Value.new(subordinate_key('r')).get
      end

      def to_s
        get(:name) || "Unnamed"
      end
    end

    # Walk the graph depth-first and yield encountered vertices.  Cycle detection is performed.  This
    # algorithm uses recursive calls, so beware of performance issues on deep graphs.
    class Traverser
      include Enumerable

      def initialize(start, seen = Set.new)
        @start = start
        @seen = seen
      end

      def each(&block)
        @seen << @start
        yield @start
        @start.edges.each do |e|
          unless @seen.include?(e.right)
            self.class.new(e.right, @seen).each(&block)
          end
        end
      end
    end

    def edges
      @edges ||= Authorize::Set.new(subordinate_key('edges'))
    end

    def vertices
      @vertices ||= Authorize::Set.new(subordinate_key('vertices'))
    end

    def vertex(*args)
      Vertex.new(subordinate_key("_vertices", true), *args).tap do |v|
        vertices << v
      end
    end

    def edge(*args)
      Edge.new(subordinate_key("_edges", true), *args).tap do |e|
        edges << e
      end
    end

    def traverse(start = vertices.sort_by{rand}.first)
      Traverser.new(start)
    end
  end

  class UndirectedGraph < Authorize::Graph
    # Join two vertices symetrically so that they become adjacent.  Graphs built uniquely with
    # this method will be undirected.
    def join(v0, v1, *args)
      !!(edge(v0, v1, *args) && edge(v1, v0, *args))
    end
  end
end