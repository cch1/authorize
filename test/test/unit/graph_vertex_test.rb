require 'test_helper'

class GraphVertexTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph::Vertex.index.clear # clear cache
  end

  test 'create vertex' do
    name = 'name'
    property, serialized_property = 'property', 'serialized property'
    value, serialized_value = 'value', 'serialized value'
    Marshal.expects(:dump).with(property).returns(serialized_property)
    Marshal.expects(:dump).with(value).returns(serialized_value)
    Authorize::Graph::Vertex.db.expects(:hmset).with(name, serialized_property, serialized_value)
    Authorize::Graph::Vertex.db.expects(:set).with(name + '::_', nil)
    assert_kind_of Authorize::Graph::Vertex, v = Authorize::Graph::Vertex.new(name, property => value)
  end

  test 'exists?' do
    name = 'name'
    Authorize::Graph::Vertex.db.expects(:exists).with(name + '::_', nil).returns(true)
    assert Authorize::Graph::Vertex.exists?(name)
  end

  test 'edges' do
    name, edge = 'name'
    edge, serialized_edge = 'edge', 'serialized edge'
    v = Authorize::Graph::Vertex.load(name)
    Marshal.expects(:load).with(serialized_edge).returns(edge)
    Authorize::Graph::Vertex.db.expects(:smembers).with(v.subordinate_key('edges')).returns([serialized_edge])
    assert_kind_of Authorize::Redis::Set, v.edges
    assert v.edges.include?(edge)
  end
end