require 'authorize/redis'
module Authorize
  module Graph
    class DirectedAcyclicGraph < DirectedGraph
      def traverse(*args, &block)
        DirectedAcyclicGraphTraverser.traverse(*args, &block)
      end
    end
  end
end