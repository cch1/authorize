require 'test_helper'

class GraphTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Value.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
  end

  test 'create graph' do
    assert_kind_of Authorize::Graph, g0 = Authorize::Graph.new
    assert_kind_of Authorize::Redis::Set, g0
    assert_kind_of Authorize::Redis::Set, g0.edges
  end

  test 'degenerate vertex' do
    assert_kind_of Authorize::Graph::Vertex, v = Authorize::Graph::Vertex.new
    Authorize::Graph::Vertex.index.clear
    assert Authorize::Graph::Vertex.exists?(v.id)
  end

  test 'rich vertex' do
    assert_kind_of Authorize::Graph::Vertex, v = Authorize::Graph::Vertex.new(nil, :prop => :value)
    Authorize::Graph::Vertex.index.clear
    assert_equal :value, Authorize::Graph::Vertex.new(v.id).get(:prop)
  end

  test 'degenerate edge' do
    v0, v1 = Authorize::Graph::Vertex.new, Authorize::Graph::Vertex.new
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(nil, v0, v1)
    assert_same v0, e.left
    assert_same v1, e.right
    Authorize::Graph::Edge.index.clear
    assert Authorize::Graph::Edge.exists?(e.id)
  end

  test 'rich edge' do
    v0, v1 = Authorize::Graph::Vertex.new, Authorize::Graph::Vertex.new
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(nil, v0, v1, :prop => :value)
    Authorize::Graph::Edge.index.clear
    assert_equal :value, Authorize::Graph::Edge.new(e.id).get(:prop)
  end

  test 'add vertex' do
    g0 = Authorize::Graph.new
    assert_kind_of Authorize::Graph::Vertex, v0 = g0.vertex(:name => "Charlottesville")
    assert g0.include?(v0)
  end

  test 'add edge' do
    g0 = Authorize::Graph.new
    v0, v1 = g0.vertex(:name => "Charlottesville"), g0.vertex(:name => "Richmond")
    assert_kind_of Authorize::Graph::Edge, e = g0.edge(v0, v1, :name => "I 64")
    assert v0.edges.include?(e)
    assert v1.edges.empty?
    assert_same v0, e.left
    assert_same v1, e.right
    assert g0.edges.include?(e)
  end

  test 'join vertices' do
    g0 = Authorize::UndirectedGraph.new
    v0, v1 = g0.vertex(:name => "Charlottesville"), g0.vertex(:name => "Richmond")
    assert g0.join(v0, v1, :name => "I 64")
    [[v0, v1], [v1, v0]].each do |(vl, vr)|
      assert_equal 1, vl.edges.size
      assert_kind_of Authorize::Graph::Edge, e = vl.edges.to_a.first
      assert_same vr, e.right
      assert g0.edges.include?(e)
    end
  end

  test 'traverse acyclic graph' do
    g0 = Authorize::Graph.new
    v0 = g0.vertex(:name => "Charlottesville")
    v1 = g0.vertex(:name => "Richmond")
    v2 = g0.vertex(:name => "Springfield")
    v3 = g0.vertex(:name => "Dunn Loring")
    v4 = g0.vertex(:name => "Centreville")
    v5 = g0.vertex(:name => "Strasburg")
    v6 = g0.vertex(:name => "Staunton")
    e0 = g0.edge(v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.edge(v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.edge(v2, v3, :name => "I 495", :cost => 20)
    e3 = g0.edge(v3, v4, :name => "I 66", :cost => 40)
    e4 = g0.edge(v4, v5, :name => "I 66", :cost => 120)
    e5 = g0.edge(v5, v6, :name => "I 81", :cost => 130)
    assert_equal Set[v2, v5, v6], g0.traverse(v0).select{|v| /S.*/.match(v.get(:name))}.to_set
  end

  test 'traverse graph' do
    g0 = Authorize::UndirectedGraph.new
    v0 = g0.vertex(:name => "Charlottesville")
    v1 = g0.vertex(:name => "Richmond")
    v2 = g0.vertex(:name => "Springfield")
    v3 = g0.vertex(:name => "Dunn Loring")
    v4 = g0.vertex(:name => "Centreville")
    v5 = g0.vertex(:name => "Strasburg")
    v6 = g0.vertex(:name => "Staunton")
    e0a = g0.join(v6, v0, :name => "I 64", :cost => 95)
    e0b = g0.join(v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.join(v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.join(v2, v3, :name => "I 495", :cost => 20)
    e3a = g0.join(v3, v4, :name => "I 66", :cost => 40)
    e3b = g0.join(v4, v5, :name => "I 66", :cost => 120)
    e4 = g0.join(v5, v6, :name => "I 81", :cost => 130)
    e5 = g0.join(v0, v4, :name => "US 29", :cost => 200)
    assert_equal 7, g0.traverse.to_set.size
  end

  test 'traverse acyclic graph from vertex' do
    g0 = Authorize::Graph.new
    v0 = g0.vertex(:name => "Charlottesville")
    v1 = g0.vertex(:name => "Richmond")
    v2 = g0.vertex(:name => "Springfield")
    v3 = g0.vertex(:name => "Dunn Loring")
    v4 = g0.vertex(:name => "Centreville")
    v5 = g0.vertex(:name => "Strasburg")
    v6 = g0.vertex(:name => "Staunton")
    e0 = g0.edge(v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.edge(v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.edge(v2, v3, :name => "I 495", :cost => 20)
    e3 = g0.edge(v3, v4, :name => "I 66", :cost => 40)
    e4 = g0.edge(v4, v5, :name => "I 66", :cost => 120)
    e5 = g0.edge(v5, v6, :name => "I 81", :cost => 130)
    assert_equal Set[v3, v4, v5, v6], v3.traverse.to_set
  end
end