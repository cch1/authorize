require 'test_helper'

class GraphEdgeTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Edge.index.clear # clear cache
    @factory = Authorize::Graph::Factory.new
  end

  test 'create edge from one vertex to another' do
    name = 'name'
    property, value = 'property', 'value'
    from_id, to_id = 'from', 'to'
    from_edges = []
    from = mock('from', :edge_ids => from_edges, :id => from_id)
    to = mock('to', :id => to_id)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(name, from, to, property => value)
    assert_equal e.id, from_edges[0]
    assert !Authorize::Graph::Edge.db.keys(e.id + '*').empty?
  end

  test 'exists?' do
    create_graph
    assert Authorize::Graph::Edge.exists?(@e0.id)
  end

  test 'from' do
    create_graph
    assert_same @from, @e0.from
  end

  test 'to' do
    create_graph
    assert_equal @to, @e0.to
  end

  test 'destroy' do
    create_graph
    @e0.destroy
    assert Authorize::Graph::Edge.db.keys(@e0.id + '*').empty?
  end

  private
  # Create a simple graph with vertex fixtures and stubbed edges (to decouple Edge implementation).
  def create_graph
    l_id, r_id = 'l_id', 'r_id'
    @e0 = @factory.edge('e0', {'property' => 'value'}, :l_id => l_id, :r_id => r_id)
    @from = stub('from', :id => l_id)
    @to = stub('to', :id => r_id)
    Authorize::Graph::Vertex.stubs(:load).with(@from.id).returns(@from)
    Authorize::Graph::Vertex.stubs(:load).with(@to.id).returns(@to)
  end
end