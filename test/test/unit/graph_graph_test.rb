require 'test_helper'

class GraphGraphTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
  end

  test 'create graph' do
    assert_kind_of Authorize::Graph::Graph, g0 = Authorize::Graph::Graph.new
    assert_kind_of Authorize::Redis::Set, g0
    assert_kind_of ::Enumerable, g0.vertices
  end

  test 'exists' do
    name = 'name'
    Authorize::Graph::Vertex.db.expects(:keys).with(name + '::*', nil).returns([name + '::something'])
    assert Authorize::Graph::Graph.exists?(name)
  end

  test 'add vertex' do
    g0 = Authorize::Graph::Graph.new
    assert_kind_of Authorize::Graph::Vertex, v0 = g0.vertex("Charlottesville")
    assert g0.vertices.include?(v0)
  end

  test 'add edge' do
    g0 = Authorize::Graph::Graph.new
    v0, v1 = g0.vertex("Charlottesville"), g0.vertex("Richmond")
    assert_kind_of Authorize::Graph::Edge, e = g0.edge("I64", v0, v1)
    assert v0.edges.include?(e)
    assert v1.edges.empty?
    assert_equal v0, e.from
    assert_equal v1, e.to
    assert g0.edges.include?(e)
  end

  test 'join vertices' do
    g0 = Authorize::Graph::UndirectedGraph.new
    v0, v1 = g0.vertex("Charlottesville"), g0.vertex("Richmond")
    assert g0.join("I64", v0, v1)
    [[v0, v1], [v1, v0]].each do |(vl, vr)|
      assert vl.neighbors.include?(vr)
    end
  end
end