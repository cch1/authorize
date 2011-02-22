require 'enumerator'

module Authorize
  module Graph
    class DirectedAcyclicGraphTraverser < Traverser
      def traverse(check = false, &block)
        super(&block) unless check
        self.class.new(self, :traverse).acyclic_assertor.cost_collector
      end

      def acyclic_assertor(&block)
        return self.class.new(self, :acyclic_assertor).cycle_detector unless block_given?
        self.each do |vertex, edge|
          raise "Cycle detected at #{vertex} along #{edge}" unless yield vertex, edge
          true
        end
      end
    end
  end
end
