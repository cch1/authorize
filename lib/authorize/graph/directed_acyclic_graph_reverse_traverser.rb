require 'enumerator'

module Authorize
  module Graph
    class DirectedAcyclicGraphReverseTraverser < DirectedAcyclicGraphTraverser
      private
      # Recursively traverse vertices breadth-wise, in reverse.
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_breadth_first(start, depth, &block)
        depth += 1
        start.inbound_edges.select{|e| yield(e.from, e, depth)}.each do |e|
          _traverse_breadth_first(e.from, depth, &block)
        end
      end

      # Recursively traverse vertices depth-wise, in reverse.
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_depth_first(start, depth, &block)
        depth += 1
        start.inbound_edges.each do |e|
          _traverse_depth_first(e.from, depth, &block) if yield(e.from, e, depth)
        end
      end
      alias _traverse _traverse_depth_first
    end
  end
end
