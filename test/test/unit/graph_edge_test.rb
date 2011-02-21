require 'test_helper'

class GraphEdgeTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Edge.index.clear # clear cache
    create_graph
  end

  test 'create edge from one vertex to another' do
    name = 'name'
    property, value = 'property', 'value'
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(name, @cho, @spr, property => value)
    assert @cho.outbound_edges.include?(e)
    assert @spr.inbound_edges.include?(e)
    assert !Authorize::Graph::Edge.db.keys(e.id + '*').empty?
  end

  test 'exists?' do
    assert Authorize::Graph::Edge.exists?(@e0.id)
  end

  test 'from' do
    assert_same @cho, @e0.from
  end

  test 'to' do
    assert_equal @ric, @e0.to
  end

  test 'destroy' do
    @e0.destroy
    assert !@cho.outbound_edges.include?(@e0)
    assert !@ric.inbound_edges.include?(@e0)
    assert Authorize::Graph::Edge.db.keys(@e0.id + '*').empty?
  end

  private
  # Create a simple graph with edge fixtures and stubbed vertices (to decouple Vertex implementation).
  def create_graph
    @factory = Authorize::Graph::Factory.new
    l_id, r_id = 'l_id', 'r_id'
    @e0 = @factory.edge('e0', {'property' => 'value'}, :l_id => l_id, :r_id => r_id)
    @cho = stub('cho', :id => l_id, :outbound_edges => Set[@e0])
    @ric = stub('ric', :id => r_id, :inbound_edges => Set[@e0])
    @spr = stub('spr', :id => 'spr', :inbound_edges => Set[])
    Authorize::Graph::Vertex.stubs(:load).with(@cho.id).returns(@cho)
    Authorize::Graph::Vertex.stubs(:load).with(@ric.id).returns(@ric)
  end
end