require 'authorize/redis'
module Authorize
  module Graph
    # A directed graph implementation.  Every edge either connects "to" a vertex or "from" it.
    # This implementation ensures that edges are not duplicated (which precludes multigraphs).  In
    # cases where a duplicate edge is requested, the given properties are merged with the properties
    # of the existing edge and the existing edge is returned.

    # Notes:
    #   Edges are created in the context of a graph in order to allow for graph-specific indexing
    class DirectedGraph < Graph::Graph
      # Find or create a directed edge joining the given vertices
      def join(id, v0, v1, properties = {})
        existing_edge = v0.edges.detect{|e| v1.eql?(e.to)}
        existing_edge.try(:merge, properties)
        existing_edge || Edge.new(id, v0, v1, properties).tap do |edge|
          edge_ids << edge.id
        end
      end

      def disjoin(v0, v1)
        return unless existing_edge = v0.edges.detect{|e| v1.eql?(e.to)}
        existing_edge.tap do |edge|
          edge.destroy
          edge_ids.delete(edge.id)
        end
      end
    end
  end
end