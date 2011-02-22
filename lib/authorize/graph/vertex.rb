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
  
      # Visit this vertex and recursively visit adjacencies.
      # This method manages the edge case of needing to visit the first vertex (self) without
      # actually traversing any edges.
      def traverse(&block)
        yield(self, nil) # The canonical "visit".
        _traverse(&block)
      end
  
      protected
      # Traverse adjacent vertices breadth-wise
      # Traversal is pruned if the visit block returns an untrue value.
      def _traverse_breadth_first(edge = nil, &block)
        outbound_edges.select{|e| yield(e.to, e)}.each do |e|
          e.to._traverse_breadth_first(e, &block)
        end
      end
  
      # Traverse adjacent vertices depth-wise
      # Traversal is pruned if the visit block returns an untrue value.
      def _traverse_depth_first(edge = nil, &block)
        outbound_edges.each do |e|
          e.to._traverse_depth_first(e, &block) if yield(e.to, e)
        end
      end
      alias _traverse _traverse_depth_first
    end
  end
end