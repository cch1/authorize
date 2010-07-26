require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")
require 'authorize/redis'

class RedisTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis.db.flushdb
    Authorize::Value.index.clear # Clear the cache
    Authorize::Set.index.clear
    Authorize::Hash.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    Authorize::Redis.db.set('x', 'x')
  end

  test 'coherent identity from cache' do
    assert o0 = Authorize::Value.new('xyx')
    assert o1 = Authorize::Value.new('xyx')
    assert_same o0, o1
  end

  uses_mocha "track initialization process" do
    test 'initialize semantics' do
      Authorize::Value.any_instance.expects(:initialize).once
      Authorize::Value.any_instance.expects(:reloaded).never
      Authorize::Value.new('new_key')
    end

    test 'reload semantics' do
      Authorize::Value.any_instance.expects(:reloaded)
      Authorize::Value.any_instance.expects(:initialize).never
      assert val1 = Authorize::Value.new('x')
    end
  end

  # Can Redis objects be serialized according to conventional contracts?
  test 'serializability' do
    v0 = Authorize::Value.new
    v0.set("Hi Mom")
    assert_instance_of String, s = Marshal.dump(v0)
    assert_instance_of Authorize::Value, v1 = Marshal.load(s)
    assert_equal v0, v1
  end

  # Do serialized and re-hyrdrated Redis objects honor the strict coherent identity contract?
  test 'coherency through serialization' do
    v0 = Authorize::Value.new
    v0.set("Hi Mom")
    v1 = Marshal.load(Marshal.dump(v0))
    assert_same v0, v1
  end

  # Are serializable objects properly stored and retrieved?
  test 'serialization of values' do
    a = [1,2,3]
    v0 = Authorize::Value.new
    v0.set(a)
    b = v0.get
    assert_equal a, b
  end

  # Do Redis objects stored and retrieved as values honor the coherency contract?
  # This is a test of the strict serializability of Redis objects and the serialization of values.
  test 'serialization as value' do
    a = Authorize::Set.new
    a.add(1);a.add(2);a.add(3)
    v0 = Authorize::Value.new
    v0.set(a)
    b = v0.get
    assert_same a, b
  end

# -------------------------------------------------------------------

  test 'create graph' do
    assert_kind_of Authorize::Graph, g0 = Authorize::Graph.new
    assert_kind_of Authorize::Set, g0.vertices
    assert_kind_of Authorize::Set, g0.edges
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
    assert g0.vertices.include?(v0)
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
      assert_kind_of Authorize::Graph::Edge, e = vl.edges.first
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
end