require 'authorize/redis'
module Authorize
  module Graph
    class DirectedAcyclicGraph < Authorize::Graph::DirectedGraph
      def traverse(*args)
        DirectedAcyclicGraphTraverser.traverse(*args)
      end
    end
  end
end
