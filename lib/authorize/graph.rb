require 'authorize/redis'

module Authorize
  # A binary property graph.  Vertices and Edges have an arbitrary set of named properties.
  # Reference: http://www.nist.gov/dads/HTML/graph.html
  class Graph < Authorize::Redis::Set
    class Vertex < Authorize::Redis::Hash
      def self.exists?(id)
        super(subordinate_key(id, '_'))
      end

      def initialize(properties = {})
        super()
        # Because a degenerate vertex can have neither properties nor edges, we must store a marker to indicate existence
        self.class.db.set(subordinate_key('_'), nil)
        merge(properties) if properties.any?
      end

      def edges
        @edges ||= Redis::Set.load(subordinate_key('edges'))
      end

      def neighbors
        edges.map{|e| e.right}
      end

      def traverse(options = {})
        Traverser.new(self)
      end
    end

    # An edge connects two vertices.  The edge is directed from left to right only (unidirectional), but references are
    # available in both directions.
    # TODO: a hyperedge can be modeled with a set of vertices instead of explicit left and right vertices.
    class Edge < Authorize::Redis::Hash
      def self.exists?(id)
        super(subordinate_key(id, 'l'))
      end

      def initialize(v0, v1, properties = {})
        super()
        self.class.db.set(subordinate_key('l'), Marshal.dump(v0))
        self.class.db.set(subordinate_key('r'), Marshal.dump(v1))
        v0.edges << self
        merge(properties) if properties.any?
        @l, @r = v0, v1
      end

      def left
        @l ||= Marshal.load(self.class.db.get(subordinate_key('l')))
      end

      def right
        @r ||= Marshal.load(self.class.db.get(subordinate_key('r')))
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

    def self.exists?(id)
      db.keys([id, '*'].join(':'))
    end

    def edges
      @edges ||= Redis::Set.load(subordinate_key('edges'))
    end

    def vertex(id, *args)
      Vertex.new(id || subordinate_key("_vertices", true), *args).tap do |v|
        add(v)
      end
    end

    def edge(id, *args)
      Edge.new(id || subordinate_key("_edges", true), *args).tap do |e|
        edges << e
      end
    end

    def traverse(start = sort_by{rand}.first)
      Traverser.new(start)
    end
  end

  class UndirectedGraph < Authorize::Graph
    # Join two vertices symetrically so that they become adjacent.  Graphs built uniquely with
    # this method will be undirected.
    def join(id, v0, v1, *args)
      edge_id = id || subordinate_key("_edges", true)
      !!(edge(edge_id + "-01", v0, v1, *args) && edge(edge_id + "-10", v1, v0, *args))
    end
  end
end