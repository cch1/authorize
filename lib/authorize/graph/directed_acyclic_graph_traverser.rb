require 'authorize/redis'
require 'enumerator'

# Walk the graph and yield encountered vertices.  The graph is assumed to be acyclic and no cycle detection is performed
# unless the check parameter is true.  This algorithm uses recursive calls, so beware of heap/stack issues on deep graphs,
# and memory issues if the check option is used.
module Authorize
  module Graph
    class DirectedAcyclicGraphTraverser
      def self.traverse(start, check = false)
        enumerator = check ? :traverse_safely : :traverse
        self.new.to_enum(enumerator, start)
      end

      def initialize
        reset!
      end

      def reset!
        @odometer = 0
      end

      def traverse(start, &block)
        yield start
        start.edges.each do |e|
          @odometer += 1
          traverse(e.to, &block)
        end
        @odometer
      end

      def traverse_safely(start, &block)
        seen = ::Set.new
        traverse(start) do |vertex|
          raise "Cycle detected at #{vertex} (Odometer at #{@odometer})!" if seen.include?(vertex)
          seen << vertex
          yield vertex
        end.tap {seen = nil}
      end
    end
  end
end
