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

  test 'left' do
    create_graph
    assert_same @left, @e0.left
  end

  test 'right' do
    create_graph
    assert_equal @right, @e0.right
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
    @left = stub('left', :id => l_id)
    @right = stub('right', :id => r_id)
    Authorize::Graph::Vertex.stubs(:load).with(@left.id).returns(@left)
    Authorize::Graph::Vertex.stubs(:load).with(@right.id).returns(@right)
  end
end