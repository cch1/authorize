module Authorize
  module Graph
    # An edge connects two vertices.  The order in which the vertices are supplied is preserved and can be
    # used to imply direction.
    # TODO: persist the connected vertices in an array.
    # TODO: a hyperedge can be modeled with a set of vertices instead of explicit left and right vertices.
    class Edge < Redis::Hash
      def self.exists?(id)
        super(subordinate_key(id, 'l_id'))
      end

      def initialize(v0, v1, properties = {})
        super()
        self.class.db.set(subordinate_key('l_id'), v0.id)
        self.class.db.set(subordinate_key('r_id'), v1.id)
        v0.outbound_edges << self
        v1.inbound_edges << self
        merge(properties) if properties.any?
      end

      def from
        Vertex.load(self.class.db.get(subordinate_key('l_id')))
      end
      alias left from

      def to
        Vertex.load(self.class.db.get(subordinate_key('r_id')))
      end
      alias right to

      def vertices
        [from, to]
      end

      def destroy
        from.outbound_edges.delete(self)
        to.inbound_edges.delete(self)
        self.class.db.del(subordinate_key('l_id'))
        self.class.db.del(subordinate_key('r_id'))
        super
      end
    end
  end
end