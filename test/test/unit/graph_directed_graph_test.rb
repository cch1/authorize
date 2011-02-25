require 'test_helper'

class GraphDirectedGraphTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::DirectedGraph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    @factory = Authorize::Graph::Factory.new
    create_interstate_graph
  end

  test 'edges' do
#    assert @g0.edges.include?(@i64e)
  end

  test 'vertices' do
#    assert @g0.vertices.include?(@cho)
  end

  test 'join' do
    assert_kind_of Authorize::Graph::Edge, edge = @g0.join('I95N', @ric, @spr, {'key' => 'value'})
    assert_equal @ric, edge.from
    assert_equal @spr, edge.to
    assert @g0.edges.include?(edge)
    assert_equal 'value', edge['key']
  end

  test 'join merges properties with existing edge' do
    properties = {'lanes' => '3'}
    @i64e.expects(:merge).with(properties)
    assert_same @i64e, @g0.join('newI64E', @cho, @ric, properties)
  end

  test 'disjoin' do
    @i64e.expects(:destroy)
    e = @g0.disjoin(@cho, @ric)
    assert_same @i64e, e
  end

  test 'disjoin without an existant edge' do
    e = @g0.disjoin(@ric, @spr)
    assert_nil e
  end

  test 'traverse' do
    assert_equal Set[@cho, @ric], @g0.traverse(@cho).to_set
  end

  test 'traverse from unconnected vertex' do
    assert_equal Set[@spr], @g0.traverse(@spr).to_set
  end

  private
  def create_interstate_graph
    i64e_id, i64w_id = 'I64E', 'I64W'
    @cho = @factory.vertex('Charlottesville', {'property' => 'value'}, :edge_ids => Set[i64e_id], :inbound_edge_ids => Set[i64w_id])
    @ric = @factory.vertex('Richmond', {}, :edge_ids => Set[i64w_id], :inbound_edge_ids => Set[i64e_id])
    @spr = @factory.vertex('Springfield', {}, :edge_ids => Set[])
    @i64e = @factory.edge(i64e_id, {}, :l_id => @cho.id, :r_id => @ric.id)
    @i64w = @factory.edge(i64w_id, {}, :l_id => @ric.id, :r_id => @cho.id)
    @g0 = @factory.directed_graph('Interstates', Set[@cho.id, @ric.id, @spr.id], :edge_ids => Set[@i64e.id, @i64e.id])
  end
end