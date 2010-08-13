require 'test_helper'

class GraphTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Value.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    redis_fixtures(Authorize::Redis::Base.db, Pathname.new(fixture_path).join('redis', 'db.yml'))
  end

  test 'create graph' do
    assert_kind_of Authorize::Graph, g0 = Authorize::Graph.new
    assert_kind_of Authorize::Redis::Set, g0
    assert_kind_of Authorize::Redis::Set, g0.edges
  end

  test 'exists' do
    name = 'name'
    Authorize::Graph::Vertex.db.expects(:keys).with(name + ':*', nil).returns(true)
    assert Authorize::Graph.exists?(name)
  end

  test 'add vertex' do
    g0 = Authorize::Graph.new
    assert_kind_of Authorize::Graph::Vertex, v0 = g0.vertex("Charlottesville")
    assert g0.include?(v0)
  end

  test 'add edge' do
    g0 = Authorize::Graph.new
    v0, v1 = g0.vertex("Charlottesville"), g0.vertex("Richmond")
    assert_kind_of Authorize::Graph::Edge, e = g0.edge("I64", v0, v1)
    assert v0.edges.include?(e)
    assert v1.edges.empty?
    assert_same v0, e.left
    assert_same v1, e.right
    assert g0.edges.include?(e)
  end

  test 'join vertices' do
    g0 = Authorize::UndirectedGraph.new
    v0, v1 = g0.vertex("Charlottesville"), g0.vertex("Richmond")
    assert g0.join("I64", v0, v1)
    [[v0, v1], [v1, v0]].each do |(vl, vr)|
      assert vl.neighbors.include?(vr)
    end
  end

  test 'traverse acyclic graph' do
    g0 = Authorize::Graph.new
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    e0 = g0.edge(nil, v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.edge(nil, v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.edge(nil, v2, v3, :name => "I 495", :cost => 20)
    e3 = g0.edge(nil, v3, v4, :name => "I 66", :cost => 40)
    e4 = g0.edge(nil, v4, v5, :name => "I 66", :cost => 120)
    e5 = g0.edge(nil, v5, v6, :name => "I 81", :cost => 130)
    assert_equal Set[v2, v5, v6], g0.traverse(v0).select{|v| /S.*/.match(v.id)}.to_set
  end

  test 'traverse graph' do
    g0 = Authorize::UndirectedGraph.new("Highways")
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    e0a = g0.join(nil, v6, v0, :name => "I 64", :cost => 95)
    e0b = g0.join(nil, v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.join(nil, v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.join(nil, v2, v3, :name => "I 495", :cost => 20)
    e3a = g0.join(nil, v3, v4, :name => "I 66", :cost => 40)
    e3b = g0.join(nil, v4, v5, :name => "I 66", :cost => 120)
    e4 = g0.join(nil, v5, v6, :name => "I 81", :cost => 130)
    e5 = g0.join(nil, v0, v4, :name => "US 29", :cost => 200)
    assert_equal 7, g0.traverse.to_set.size
  end

  test 'traverse acyclic graph from vertex' do
    g0 = Authorize::Graph.new("Interstates")
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    e0 = g0.edge(nil, v0, v1, :name => "I 64", :cost => 100)
    e1 = g0.edge(nil, v1, v2, :name => "I 95", :cost => 85)
    e2 = g0.edge(nil, v2, v3, :name => "I 495", :cost => 20)
    e3 = g0.edge(nil, v3, v4, :name => "I 66", :cost => 40)
    e4 = g0.edge(nil, v4, v5, :name => "I 66", :cost => 120)
    e5 = g0.edge(nil, v5, v6, :name => "I 81", :cost => 130)
    assert_equal Set[v3, v4, v5, v6], v3.traverse.to_set
  end
end