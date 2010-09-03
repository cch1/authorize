require 'test_helper'
require 'authorize/graph/fixtures'

class FixtureTest < ActiveSupport::TestCase
  def setup
    Authorize::Graph.index.clear # Clear the cache
    Authorize::Graph::Vertex.index.clear # Clear the cache
    Authorize::Graph::Edge.index.clear # Clear the cache
    Authorize::Redis::String.index.clear
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    @type_id = 'hapgoods.com,2010/graph'
    @taguri = YAML.tagurize(@type_id)
  end

  test 'key translation' do
    assert_equal "Authorize::Role::vertices::207907133", Authorize::Graph::Fixtures.name_to_key(:chris)
  end

  test 'registered type' do
    assert_not_nil YAML.tagged_classes[@taguri]
  end

  test 'parser' do
    document = <<-HERE
    --- !hapgoods.com,2010/graph
    - one
    - two: [one]
    HERE
    assert result = YAML.parse(document)
    assert_equal @taguri, result.type_id
  end

  test 'load node' do
    document = <<-HERE
    --- !hapgoods.com,2010/graph
    - user_chris
    HERE
    v = stub('vertex')
    Authorize::Role.graph.expects(:vertex).with(name_to_key(:user_chris)).returns(v)
    YAML.load(document)
  end

  test 'link subordinate node without prior reference' do
    document = <<-HERE
    --- !hapgoods.com,2010/graph
    - user_chris: [registered_user]
    HERE
    v0, v1 = stub('vertex0'), stub('vertex1')
    Authorize::Role.graph.expects(:vertex).with(name_to_key(:user_chris)).returns(v0)
    Authorize::Role.graph.expects(:vertex).with(name_to_key(:registered_user)).returns(v1)
    Authorize::Role.graph.expects(:edge).with(nil, v0,  v1)
    assert result = YAML.load(document)
  end

  def name_to_key(name)
    Authorize::Graph::Fixtures.name_to_key(name)
  end
end