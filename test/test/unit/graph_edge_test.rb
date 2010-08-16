require 'test_helper'

class GraphEdgeTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Edge.index.clear # clear cache
  end

  test 'create edge from one vertex to another' do
    name = 'name'
    property, value = 'property', 'value'
    from_id, to_id = 'from', 'to'
    from_edges = []
    from = mock('from', :edge_ids => from_edges, :id => from_id)
    to = mock('to', :id => to_id)
    Authorize::Graph::Edge.db.expects(:hmset).with(name, property, value)
    Authorize::Graph::Edge.db.expects(:set).with(name + '::l_id', from_id)
    Authorize::Graph::Edge.db.expects(:set).with(name + '::r_id', to_id)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(name, from, to, property => value)
    assert_equal e.id, from_edges[0]
  end

  test 'exists?' do
    name = 'name'
    Authorize::Graph::Edge.db.expects(:exists).with(name + '::l_id', nil).returns(true)
    assert Authorize::Graph::Edge.exists?(name)
  end

  test 'left' do
    name, from, from_id = 'name', mock('from'), 'from_id'
    Authorize::Graph::Edge.db.expects(:get).with(name + '::l_id').returns(from_id)
    Authorize::Graph::Vertex.index.expects(:[]).with(from_id).returns(from)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.load(name)
    assert_equal from, e.left
  end

  test 'right' do
    name, to, to_id = 'name', mock('to'), 'to_id'
    Authorize::Graph::Edge.db.expects(:get).with(name + '::r_id').returns(to_id)
    Authorize::Graph::Vertex.index.expects(:[]).with(to_id).returns(to)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.load(name)
    assert_equal to, e.right
  end
end