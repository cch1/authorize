require 'enumerator'

module Authorize
  module Graph
    class DirectedAcyclicGraphReverseTraverser < DirectedAcyclicGraphTraverser
      private
      # Recursively traverse vertices breadth-wise, in reverse.
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_breadth_first(start, &block)
        start.inbound_edges.select{|e| yield(e.from, e)}.each do |e|
          _traverse_breadth_first(e.from, &block)
        end
      end

      # Recursively traverse vertices depth-wise, in reverse.
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_depth_first(start, &block)
        start.inbound_edges.each do |e|
          _traverse_depth_first(e.from, &block) if yield(e.from, e)
        end
      end
      alias _traverse _traverse_depth_first
    end
  end
end
