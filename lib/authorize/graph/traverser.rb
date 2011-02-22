require 'enumerator'

module Authorize
  module Graph
    # Traverse the graph
    class Traverser < Enumerable::Enumerator
      def self.traverse(start, &block)
        self.new(start, :traverse).cycle_detector.cost_collector.restrictor.each(&block)
      end

      # Detect cycles in the graph by accumulating a set of visited nodes.  When a cycle is detected, interrupt the
      # visit and signal the yielder.  NB: the yielder is responsible for taking further action such as pruning the
      # traversal or raising an exception (such as would be the case for an acyclic graph).
      def cycle_detector(&block)
        return self.class.new(self, :cycle_detector) unless block_given?
        seen = ::Set.new
        self.each do |vertex, edge|
          next false if seen.include?(vertex)
          seen << vertex
          yield vertex, edge
          true # Don't let client block return value influence traversal
        end
      end

      # Output the values yielded by the yielder as well as the return value of the supplied block.
      def debugger(&block)
        return self.class.new(self, :debugger) unless block_given?
        count = 0 # A transit counter that
        self.each do |*args|
          count += 1
          block.call(*args).tap do |result|
            print "#{count}\t#{result}\t" + args.join("\t") + "\n"
          end
        end
      end

      # Return the accumulated cost of traversing the graph.  The default accumulator is a simple transit counter.
      def cost_collector(cost = 0, f = lambda{|e| 1}, &block)
        return self.class.new(self, :cost_collector) unless block_given?
        # OPTIMIZE: inject/reduce *should* work here, but it interferes with the returned value.
        self.each do |vertex, edge|
          yield vertex, edge
          cost += f.call(edge)
        end
        cost
      end

      # Strip the edge from the yielded values to be more conventional.
      def restrictor(&block)
        return self.class.new(self, :restrictor) unless block_given?
        self.each do |vertex, edge|
          yield vertex
        end
      end
    end
  end
end