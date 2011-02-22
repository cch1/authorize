require 'enumerator'

module Authorize
  module Graph
    class DirectedAcyclicGraphTraverser < Traverser
      # Traverse the graph.  The graph is assumed to be acyclic and no cycle detection is performed
      # unless the check parameter is true.
      def self.traverse(start, check = false, &block)
        traverser = self.new(start, :traverse)
        traverser = traverser.acyclic_assertor.cycle_detector if check
        traverser.cost_collector.restrictor.each(&block)
      end

      def acyclic_assertor(&block)
        return self.class.new(self, :acyclic_assertor) unless block_given?
        self.each do |vertex, edge|
          raise "Cycle detected at #{vertex} along #{edge}" unless yield vertex, edge
          true
        end
      end
    end
  end
end
