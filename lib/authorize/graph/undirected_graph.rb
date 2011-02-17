require 'authorize/redis'

class Authorize::Graph::UndirectedGraph < Authorize::Graph::Graph
  # Join two vertices symmetrically so that they become adjacent.  Graphs built uniquely with
  # this method will be undirected.
  def join(id, v0, v1, *args)
    edge_id = id || subordinate_key("_edges", true)
    !!(edge(edge_id + "-01", v0, v1, *args) && edge(edge_id + "-10", v1, v0, *args))
  end
end