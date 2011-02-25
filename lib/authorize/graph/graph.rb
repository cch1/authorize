require 'authorize/redis'

module Authorize
  module Graph
    # A binary property graph.  Vertices and Edges have an arbitrary set of named properties.
    # Reference: http://www.nist.gov/dads/HTML/graph.html
    class Graph < Redis::Set
      def self.exists?(id)
        db.keys([id, '*'].join(':'))
      end

      attr_writer :edge_namespace, :vertex_namespace

      def edge_namespace
        @edge_namespace ||= subordinate_key('_edges')
      end

      def vertex_namespace
        @vertex_namespace ||= subordinate_key('_vertices')
      end

      def edges
        Edge.load_all(edge_namespace)
      end

      def vertices
        Vertex.load_all(vertex_namespace)
      end

      # Create an vertex on this graph with the given name and additional properties.
      def vertex(name, *args)
        name ||= self.class.next_counter(vertex_namespace)
        key = self.class.subordinate_key(vertex_namespace, name)
        Vertex.new(key, *args)
      end

      # Create an edge on this graph with the given name and additional properties.
      def edge(name, *args)
        name ||= self.class.next_counter(edge_namespace)
        key = self.class.subordinate_key(edge_namespace, name)
        Edge.new(key, *args)
      end

      # Load the existing vertex in this graph with the given name.
      def vertex_by_name(name)
        key = self.class.subordinate_key(vertex_namespace, name)
        Vertex.load(key)
      end

      def traverse(start = Vertex.load(sort_by{rand}.first))
        Traverser.traverse(start)
      end
    end
  end
end