require 'authorize/graph/vertex'
require 'authorize/graph/edge'
require 'authorize/redis/factory'

module Authorize
  module Graph
    class Factory < Redis::Factory
      def directed_graph(name, value = Set[], options = {}, &block)
        options = {:edge_ids => ::Set[]}.merge(options)
        obj = set(name, value) do
          set('edge_ids', options[:edge_ids])
          yield if block_given?
        end
        DirectedGraph.load(obj.id)
      end

      def vertex(name, value = {}, options = {}, &block)
        options = {:edge_ids => ::Set[], :inbound_edge_ids => ::Set[]}.merge(options)
        obj = hash(name, value) do
          string('_', nil)
          set('edge_ids', options[:edge_ids])
          set('inbound_edge_ids', options[:inbound_edge_ids])
          yield if block_given?
        end
        Vertex.load(obj.id)
      end

      def edge(name, value = {}, options = {}, &block)
        options = {:l_id => nil, :r_id => nil}.merge(options)
        obj = hash(name, value) do
          string(:l_id, options[:l_id])
          string(:r_id, options[:r_id])
          yield if block_given?
        end
        Edge.load(obj.id)
      end
    end
  end
end