module Authorize
  # An edge connects two vertices.  The order in which the vertices are supplied is preserved and can be
  # used to imply direction.
  # TODO: persist the connected vertices in an array.
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

    def vertices
      [left, right]
    end

    def destroy
      self.class.db.del(subordinate_key('l_id'))
      self.class.db.del(subordinate_key('r_id'))
      super
    end
  end
end