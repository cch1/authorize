require 'authorize/graph/vertex'
require 'authorize/graph/edge'
require 'authorize/redis/factory'

module Authorize
  class Graph::Factory < Redis::Factory
    def vertex(name, value = {}, options = {}, &block)
      options = {:edge_ids => ::Set[]}.merge(options)
      obj = hash(name, value) do
        string('_', nil)
        set('edge_ids', options[:edge_ids])
        yield if block_given?
      end
      Authorize::Graph::Vertex.load(obj.id)
    end

    def edge(name, value = {}, options = {}, &block)
      options = {:l_id => nil, :r_id => nil}.merge(options)
      obj = hash(name, value) do
        string(:l_id, options[:l_id])
        string(:r_id, options[:r_id])
        yield if block_given?
      end
      Authorize::Graph::Edge.load(obj.id)
    end
  end
end