require 'test_helper'

class GraphVertexTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Vertex.index.clear # clear cache
  end

  test 'create vertex' do
    name = 'name'
    property, value = 'property', 'value'
    Authorize::Graph::Vertex.db.expects(:hmset).with(name, property, value)
    Authorize::Graph::Vertex.db.expects(:set).with(name + '::_', nil)
    assert_kind_of Authorize::Graph::Vertex, v = Authorize::Graph::Vertex.new(name, property => value)
  end

  test 'exists?' do
    name = 'name'
    Authorize::Graph::Vertex.db.expects(:exists).with(name + '::_', nil).returns(true)
    assert Authorize::Graph::Vertex.exists?(name)
  end

  test 'edges' do
    name, edge, edge_id = 'name', mock('edge'), 'edge_id'
    v = Authorize::Graph::Vertex.load(name)
    Authorize::Graph::Vertex.db.expects(:smembers).with(v.subordinate_key('edge_ids')).returns(Set[edge_id])
    Authorize::Graph::Edge.expects(:load).with(edge_id).returns(edge)
    assert_equal Set[edge], v.edges
  end
end