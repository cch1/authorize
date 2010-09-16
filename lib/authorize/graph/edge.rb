module Authorize
  # An edge connects two vertices.  The edge is directed from left to right only (unidirectional), but references are
  # available in both directions.
  # TODO: a hyperedge can be modeled with a set of vertices instead of explicit left and right vertices.
  class Graph::Edge < Authorize::Redis::Hash
    def self.exists?(id)
      super(subordinate_key(id, 'l_id'))
    end

    def initialize(v0, v1, properties = {})
      super()
      self.class.db.set(subordinate_key('l_id'), v0.id)
      self.class.db.set(subordinate_key('r_id'), v1.id)
      v0.edge_ids << self.id
      merge(properties) if properties.any?
    end

    def left
      Graph::Vertex.load(self.class.db.get(subordinate_key('l_id')))
    end

    def right
      Graph::Vertex.load(self.class.db.get(subordinate_key('r_id')))
    end
  end
end