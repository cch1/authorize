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
  
    def neighbors
      edges.map{|e| e.right}
    end
  
    def traverse(options = {})
      Graph::Traverser.new(self)
    end
  end
end