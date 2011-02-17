require 'test_helper'

class GraphDirectedGraphTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::DirectedGraph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
  end

  test 'add directed edge' do
    g0 = Authorize::Graph::DirectedGraph.new
    v0, v1 = g0.vertex("Charlottesville"), g0.vertex("Richmond")
    assert_kind_of Authorize::Graph::Edge, e = g0.edge("I64", v0, v1)
    assert v0.edges.include?(e)
    assert v1.edges.empty?
    assert_equal v0, e.left
    assert_equal v1, e.right
    assert g0.edges.include?(e)
  end
end