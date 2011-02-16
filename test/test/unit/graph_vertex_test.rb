require 'test_helper'
require 'authorize/graph/factory'

class GraphVertexTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Vertex.index.clear # clear cache
    @factory = Authorize::Graph::Factory.new
  end

  test 'create' do
    name = 'name'
    property, value = 'property', 'value'
    v = Authorize::Graph::Vertex.new(name, property => value)
    assert_equal name, v.id
    assert !Authorize::Graph::Vertex.db.keys(v.id + '*').empty?
  end

  test 'destroy' do
    create_graph
    @edge.expects(:destroy)
    @v0.destroy
    assert Authorize::Graph::Vertex.db.keys(@v0.id + '*').empty?
  end

  test 'exists?' do
    create_graph
    assert Authorize::Graph::Vertex.exists?(@v0.id)
  end

  test 'edges' do
    create_graph
    assert_equal Set[@edge], @v0.edges
  end

  test 'adjancies' do
    create_graph
    assert_equal Set[@v1], @v0.adjancies.to_set
  end

  test 'link' do
    create_graph
    eid = 'new_edge_id'
    edge = mock('edge', :id => eid)
    properties = {'property' => 'value'}
    Authorize::Graph::Edge.expects(:new).with(nil, @v0, @v2, properties).returns(edge)
    assert_same edge, @v0.link(@v2, properties)
    assert @v0.edge_ids.include?(eid)
  end

  test 'merge with existing edge satisfies link' do
    create_graph
    properties = {'property' => 'new value'}
    @edge.expects(:merge).with(properties)
    assert_same @edge, @v0.link(@v1, properties)
  end

  test 'unlink' do
    create_graph
    @edge.expects(:destroy)
    e = @v0.unlink(@v1)
    assert_same @edge, e
    assert @v0.edge_ids.empty?
  end

  test 'unlink without an existant edge' do
    create_graph
    e = @v0.unlink(@v2)
    assert_nil e
  end

  private
  # Create a simple graph with vertex fixtures and stubbed edges (to decouple Edge implementation).
  def create_graph
    eid = 'edge_id'
    @v0 = @factory.vertex('v0', {'property' => 'value'}, :edge_ids => Set[eid])
    @v1 = @factory.vertex('v1', {}, :edge_ids => Set[])
    @v2 = @factory.vertex('v2', {}, :edge_ids => Set[])
    @edge = stub('edge', :id => eid, :left => @v0, :right => @v1)
    Authorize::Graph::Edge.stubs(:load).with(@edge.id).returns(@edge)
  end
end