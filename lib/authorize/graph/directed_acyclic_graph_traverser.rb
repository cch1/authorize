require 'enumerator'

module Authorize
  module Graph
    class DirectedAcyclicGraphTraverser < Traverser
      def traverse(check = false, &block)
        super(&block) unless check
        t = self.class.new(self, :traverse)
        if check
          t.cycle_detector.pruner.cost_collector
        else
          t.pruner.cost_collector
        end
      end

      # Detect cycles in the graph by recording the path taken (effectively an array of visited vertices indexed by
      # depth).  When a cycle is detected (by finding the current vertex earlier in the path), raise an exception.
      def cycle_detector(&block)
        return self.class.new(self, :cycle_detector) unless block_given?
        seen = ::Array.new
        self.each do |vertex, edge, depth|
          found = seen.index(vertex)
          raise "Cycle detected at #{vertex} along #{edge} at depth #{found} and #{depth}" if found && (found < depth)
          seen[depth] = vertex
          yield vertex, edge, depth
        end
      end
    end
  end
end