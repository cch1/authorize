module Authorize
  module Graph
    class Vertex < Redis::Hash
      def self.exists?(id)
        super(subordinate_key(id, '_'))
      end

      def initialize(properties = {})
        super()
        # Because a degenerate vertex can have neither properties nor edges, we must store a marker to indicate existence
        self.class.db.set(subordinate_key('_'), nil)
        merge(properties) if properties.any?
      end

      def destroy
        outbound_edges.each{|e| e.destroy}
        outbound_edges.destroy
        inbound_edges.each{|e| e.destroy}
        inbound_edges.destroy
        self.class.db.del(subordinate_key('_'))
        super
      end

      def adjacencies
        outbound_edges.map(&:to)
      end
      alias neighbors adjacencies

      def outbound_edges
        @edges || Redis::ModelSet.new(subordinate_key('edge_ids'), Edge)
      end
      alias edges outbound_edges

      # This index is required for efficient backlinking, such as when deleting a vertex.
      def inbound_edges
        @inbound_edges || Redis::ModelSet.new(subordinate_key('inbound_edge_ids'), Edge)
      end

      # Visit this vertex via the given edge
      def visit(edge, &block)
        yield self
      end
    end
  end
end