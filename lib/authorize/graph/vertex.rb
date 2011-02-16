module Authorize
  class Graph::Vertex < Authorize::Redis::Hash
    def self.exists?(id)
      super(subordinate_key(id, '_'))
    end

    def initialize(properties = {})
      super()
      # Because a degenerate vertex can have neither properties nor edges, we must store a marker to indicate existence
      self.class.db.set(subordinate_key('_'), nil)
      merge(properties) if properties.any?
    end

    def edge_ids
      Redis::Set.load(subordinate_key('edge_ids'))
    end

    def edges
      edge_ids.map{|id| Graph::Edge.load(id)}.to_set
    end

    def adjancies
      edges.map{|e| e.right}
    end
    alias neighbors adjancies

    def link(other, properties = {})
      existing_edge = edges.detect{|e| other.id == e.right.id}
      existing_edge && existing_edge.merge(properties)
      existing_edge || Graph::Edge.new(nil, self, other, properties).tap do |edge|
        edge_ids << edge.id
      end
    end

    def unlink(other)
      edges.detect{|e| other.id == e.right.id}.tap do |edge|
        if edge
          edge_ids.delete(edge.id)
          edge.destroy
        end
      end
    end

    def traverse(options = {})
      Graph::Traverser.new(self)
    end

    def destroy
      edges.each{|e| e.destroy}
      edge_ids.destroy
      self.class.db.del(subordinate_key('_'))
      super
    end
  end
end