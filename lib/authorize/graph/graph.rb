require 'authorize/redis'

module Authorize
  module Graph
    # A binary property graph.  Vertices and Edges have an arbitrary set of named properties.
    # Reference: http://www.nist.gov/dads/HTML/graph.html
    class Graph < Authorize::Redis::Set
      def self.exists?(id)
        db.keys([id, '*'].join(':'))
      end

      def edge_ids
        Redis::Set.load(subordinate_key('edge_ids'))
      end

      def edges
        edge_ids.map{|id| Edge.load(id)}.to_set
      end

      def vertices
        map{|id| Vertex.load(id)}.to_set
      end

      def vertex(id, *args)
        Vertex.new(id || subordinate_key("_vertices", true), *args).tap do |v|
          add(v.id)
        end
      end

      def edge(id, *args)
        Edge.new(id || subordinate_key("_edges", true), *args).tap do |e|
          edge_ids << e.id
        end
      end

      def traverse(start = Vertex.load(sort_by{rand}.first))
        Traverser.new(start)
      end
    end
  end
end