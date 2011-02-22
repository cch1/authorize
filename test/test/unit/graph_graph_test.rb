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
    assert_kind_of ::Set, g0.edges
    assert_kind_of ::Set, g0.vertices
  end

  test 'exists' do
    name = 'name'
    Authorize::Graph::Vertex.db.expects(:keys).with(name + ':*', nil).returns(true)
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

  test 'traverse graph' do
    g0 = Authorize::Graph::UndirectedGraph.new("Highways")
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn_Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    v7 = g0.vertex("Roanoke")
    e0a = g0.join(nil, v6, v0, :name => "I64", :cost => 95)
    e0b = g0.join(nil, v0, v1, :name => "I64", :cost => 100)
    e1 = g0.join(nil, v1, v2, :name => "I95", :cost => 85)
    e2 = g0.join(nil, v2, v3, :name => "I495", :cost => 20)
    e3a = g0.join(nil, v3, v4, :name => "I66", :cost => 40)
    e3b = g0.join(nil, v4, v5, :name => "I66", :cost => 120)
    e4 = g0.join(nil, v5, v6, :name => "I81", :cost => 130)
    e5 = g0.join(nil, v6, v7, :name => "I81", :cost => 125)
    e5 = g0.join(nil, v0, v4, :name => "US29", :cost => 200)
    assert_equal Set[v0, v1, v2, v3, v4, v5, v6, v7], g0.traverse.to_set
    assert_equal 8, g0.traverse.count
  end
end