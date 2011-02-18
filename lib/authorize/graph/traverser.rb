require 'authorize/redis'
require 'enumerator'

module Authorize
  module Graph
    # Walk the graph depth-first and yield encountered vertices.  Cycle detection is performed.  This
    # algorithm uses recursive calls, so beware of performance issues on deep graphs.
    class Traverser
      include Enumerable

      def initialize(start, seen = Set.new)
        @start = start
        @seen = seen
      end

      def each(&block)
        @seen << @start
        yield @start
        @start.edges.each do |e|
          unless @seen.include?(e.to)
            self.class.new(e.to, @seen).each(&block)
          end
        end
      end
    end
  end
end