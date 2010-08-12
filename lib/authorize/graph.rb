require 'authorize/redis'

module Authorize
  # A binary property graph.  Vertices and Edges have an arbitrary set of named properties.
  # Reference: http://www.nist.gov/dads/HTML/graph.html
  class Graph < Authorize::Redis::Base
    class Vertex < Authorize::Redis::Hash
      # Because a degenerate vertex can have neither properties nor edges, we must store a marker to indicate existence
      def self.exists?(id)
        super([id, 'marker'].join(':'))
      end

      def initialize(properties = {})
        super()
        Redis::Value.new(subordinate_key('marker')).set(nil)
        merge(properties) if properties.any?
      end

      def edges
        @edges ||= Redis::Set.new(subordinate_key('edges'))
      end

      def neighbors
        edges.map{|e| e.right}
      end

      def traverse(options = {})
        Traverser.new(self)
      end

      def to_s
        get(:name) || "Unnamed"
      end
    end

    # An edge connects two vertices.  The edge is directed from left to right only (unidirectional), but references are
    # available in both directions.
    # TODO: a hyperedge can be modeled with a set of vertices instead of explicit left and right vertices.
    class Edge < Authorize::Redis::Hash
      # Because a degenerate edge may have no properties and only left and right vertices, we need to adjust our definition of existence
      def self.exists?(id)
        super([id, 'l'].join(':'))
      end

      def initialize(v0, v1, properties = {})
        super()
        Redis::Value.new(subordinate_key('l')).set(v0)
        Redis::Value.new(subordinate_key('r')).set(v1)
        v0.edges << self
        merge(properties) if properties.any?
        @l, @r = v0, v1
      end

      def left
        @l ||= Redis::Value.new(subordinate_key('l')).get
      end

      def right
        @r ||= Redis::Value.new(subordinate_key('r')).get
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
      @edges ||= Redis::Set.new(subordinate_key('edges'))
    end

    def vertices
      @vertices ||= Redis::Set.new(subordinate_key('vertices'))
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