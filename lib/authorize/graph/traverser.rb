require 'enumerator'

module Authorize
  module Graph
    # Traverse the graph by enumerating the encountered vertices.
    class Traverser < Enumerable::Enumerator
      # Traverse the graph starting at the given vertex.  A "bootstrap" enumerator is created from the starting
      # vertex.  The bootstrap enumerator is then passed through a recursive expander and finally, several filters.
      # In ruby 1.9, bootstrapping could be simplified with an anonymous enumerator (Enumerator.new {})
      def self.traverse(start, *args, &block)
        self.new(start, :tap).traverse(*args).visit(&block)
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
        inject(cost) do |total, (vertex, edge)|
          yield vertex, edge
          total + f.call(edge)
        end
      end

      # Invoke callback on vertex.  Strip the edge to be more conventional.
      # This is typically the last filter in the traverse chain.
      def visit(&block)
        return self.class.new(self, :visit) unless block_given?
        self.each do |vertex, edge|
          vertex.visit(edge, &block)
        end
      end

      # Visit the yielded start vertex and traverse to its adjacencies.
      # This operation effectively "expands" the enumerator.
      def traverse(&block)
        return self.class.new(self, :traverse).cycle_detector.cost_collector unless block_given?
        each do |vertex, edge|
          yield vertex, edge
          _traverse(vertex, &block)
        end
      end

      private
      # Recursively traverse vertices breadth-wise
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_breadth_first(start, &block)
        start.outbound_edges.select{|e| yield(e.to, e)}.each do |e|
          _traverse_breadth_first(e.to, &block)
        end
      end

      # Recursively traverse vertices depth-wise
      # Traversal is pruned if the block returns an untrue value.
      def _traverse_depth_first(start, &block)
        start.outbound_edges.each do |e|
          _traverse_depth_first(e.to, &block) if yield(e.to, e)
        end
      end
      alias _traverse _traverse_depth_first
    end
  end
end