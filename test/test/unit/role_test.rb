require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    Authorize::Redis::Value.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    redis_fixtures(Authorize::Redis::Base.db, Pathname.new(fixture_path).join('redis', 'db.yml'))
  end

  test 'new global' do
    assert r = Authorize::Role.new(:name => 'Master of the Universe')
    assert r.valid?
  end

  test 'new' do
    assert r = Authorize::Role.new(:name => 'friend of %s', :_resource => users(:chris))
    assert r.valid?
  end
  
  test 'create' do
    Authorize::Graph.db.expects(:set).with(regexp_matches(/Authorize::Role::vertices::\d*::_/), nil).returns(true)
    assert_difference 'Authorize::Role.count' do
      r = Authorize::Role.create(:name => 'friend of %s', :_resource => users(:chris))
    end
  end

  test 'new identity' do
    assert r = Authorize::Role.new(:_resource => users(:pascale))
    assert r.valid?, r.errors.full_messages
  end

  test 'unique name in resource scope' do
    assert r = Authorize::Role.new(:name => 'administrator')
    assert !r.valid?
    assert r.errors[:name]
  end

  test 'has permissions' do
    assert_equal Set[permissions(:b_overlord)], roles(:administrator).permissions.to_set
  end

  test 'stringify' do
    assert_kind_of String, roles(:administrator).to_s
    assert_kind_of String, roles(:c).to_s
    assert_equal users(:chris).to_s, roles(:user_chris).to_s
  end

  test 'vertex' do
    assert_kind_of Authorize::Graph::Vertex, v = roles(:user_chris).vertex
  end

  test 'child roles' do
    assert_equal Set[roles(:registered_users), roles(:public)], roles(:user_chris).children
  end
end