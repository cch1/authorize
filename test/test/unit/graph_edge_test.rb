require 'test_helper'

class GraphEdgeTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Edge.index.clear # clear cache
  end

  test 'create edge from one vertex to another' do
    name = 'name'
    property, serialized_property = 'property', 'serialized property'
    value, serialized_value = 'value', 'serialized value'
    from_edges = []
    from = mock('from') do
      expects(:edges).returns(from_edges)
    end
    to = mock('to')
    serialized_from, serialized_to = 'serialized from', 'serialized to'
    Marshal.expects(:dump).with(property).returns(serialized_property)
    Marshal.expects(:dump).with(value).returns(serialized_value)
    Marshal.expects(:dump).with(from).returns(serialized_from)
    Marshal.expects(:dump).with(to).returns(serialized_to)
    Authorize::Graph::Vertex.db.expects(:hmset).with(name, serialized_property, serialized_value)
    Authorize::Graph::Vertex.db.expects(:set).with(name + ':l', serialized_from)
    Authorize::Graph::Vertex.db.expects(:set).with(name + ':r', serialized_to)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.new(name, from, to, property => value)
    assert_equal e, from_edges[0]
  end

  test 'exists?' do
    name = 'name'
    Authorize::Graph::Edge.db.expects(:exists).with(name + ':l', nil).returns(true)
    assert Authorize::Graph::Edge.exists?(name)
  end

  test 'left' do
    name = 'name'
    from, serialized_from = 'from', 'serialized from'
    Marshal.expects(:load).with(serialized_from).returns(from)
    Authorize::Graph::Vertex.db.expects(:get).with(name + ':l').returns(serialized_from)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.load(name)
    assert_equal from, e.left
  end

  test 'right' do
    name = 'name'
    to, serialized_to = 'to', 'serialized to'
    Marshal.expects(:load).with(serialized_to).returns(to)
    Authorize::Graph::Vertex.db.expects(:get).with(name + ':r').returns(serialized_to)
    assert_kind_of Authorize::Graph::Edge, e = Authorize::Graph::Edge.load(name)
    assert_equal to, e.right
  end
end