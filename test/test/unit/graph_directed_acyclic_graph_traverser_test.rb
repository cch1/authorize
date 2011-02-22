require 'test_helper'
require 'authorize/graph/directed_acyclic_graph_traverser'

class GraphDirectedAcyclicGraphTraverserTest < ActiveSupport::TestCase
  include Authorize::Graph

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    DirectedAcyclicGraph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
  end

  test 'traverse DAG' do
    g0 = DirectedAcyclicGraph.new
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn_Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    e0 = g0.edge(nil, v0, v1, :name => "I64", :cost => 100)
    e1 = g0.edge(nil, v1, v2, :name => "I95", :cost => 85)
    e2 = g0.edge(nil, v2, v3, :name => "I495", :cost => 20)
    e3 = g0.edge(nil, v3, v4, :name => "I66", :cost => 40)
    e4 = g0.edge(nil, v4, v5, :name => "I66", :cost => 120)
    e5 = g0.edge(nil, v5, v6, :name => "I81", :cost => 130)
    assert_equal Set[v2, v5, v6], DirectedAcyclicGraphTraverser.traverse(v0).select{|v| /S.*/.match(v.id)}.to_set
  end

  test 'traverse DAG from vertex' do
    g0 = DirectedAcyclicGraph.new("Interstates")
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    v2 = g0.vertex("Springfield")
    v3 = g0.vertex("Dunn_Loring")
    v4 = g0.vertex("Centreville")
    v5 = g0.vertex("Strasburg")
    v6 = g0.vertex("Staunton")
    e0 = g0.edge("I64", v0, v1, :name => "I64", :cost => 100)
    e1 = g0.edge("I95", v1, v2, :name => "I95", :cost => 85)
    e2 = g0.edge("I495", v2, v3, :name => "I495", :cost => 20)
    e3 = g0.edge("I66a", v3, v4, :name => "I66", :cost => 40)
    e4 = g0.edge("I66b", v4, v5, :name => "I66", :cost => 120)
    e5 = g0.edge("I81", v5, v6, :name => "I81", :cost => 130)
    assert_equal Set[v3, v4, v5, v6], DirectedAcyclicGraphTraverser.traverse(v3).to_set
  end

  test 'traverse cyclic DAG with checking' do
    g0 = DirectedAcyclicGraph.new("Interstates")
    v0 = g0.vertex("Charlottesville")
    v1 = g0.vertex("Richmond")
    e0a = g0.edge(nil, v0, v1, :name => "I64", :cost => 100)
    e0b = g0.edge(nil, v1, v0, :name => "I64", :cost => 100)
    assert_raises RuntimeError do
      DirectedAcyclicGraphTraverser.traverse(v0, true).to_set
    end
  end
end