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

  test 'destroy removes inbound edges' do
    create_graph
    @edge.expects(:destroy)
    @v1.destroy
    assert Authorize::Graph::Vertex.db.keys(@v1.id + '*').empty?
  end

  test 'exists?' do
    create_graph
    assert Authorize::Graph::Vertex.exists?(@v0.id)
  end

  test 'edges' do
    create_graph
    assert_equal Set[@edge], @v0.edges.to_set
  end

  test 'adjancies' do
    create_graph
    assert_equal Set[@v1], @v0.adjancies.to_set
  end

  private
  # Create a simple graph with vertex fixtures and stubbed edges (to decouple Edge implementation).
  def create_graph
    eid = 'edge_id'
    @v0 = @factory.vertex('v0', {'property' => 'value'}, :edge_ids => Set[eid])
    @v1 = @factory.vertex('v1', {}, :edge_ids => Set[], :inbound_edge_ids => Set[eid])
    @v2 = @factory.vertex('v2', {}, :edge_ids => Set[])
    @edge = stub('edge', :id => eid, :from => @v0, :to => @v1)
    Authorize::Graph::Edge.stubs(:load).with(@edge.id).returns(@edge)
  end
end