require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    redis_fixtures(Authorize::Redis::Base.db, Pathname.new(fixture_path).join('redis', 'role_graph.yml'))
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

  test 'can adds modes to existing permission' do
    p = permissions(:e_delete_bar)
    mask = p.mask + [:update]
    assert_equal mask, roles(:e).can(:update, widgets(:bar))
    assert p.reload.mask.include?(:update)
  end

  test 'cannot removes modes from existing permission' do
    p = permissions(:e_delete_bar)
    mask = p.mask - [:delete]
    assert_equal mask , roles(:e).cannot(:delete, widgets(:bar))
    assert !p.reload.mask.include?(:update)
  end

  test 'can inserts permission as required' do
    assert_difference "Authorize::Permission.count", 1 do
      assert_equal Set[:list, :update], roles(:e).can(:update, widgets(:foo))
    end
    assert !Authorize::Permission.effective(widgets(:foo), [roles(:e)]).empty?
  end

  test 'cannot deletes permission as required' do
    assert_difference "Authorize::Permission.count", -1 do
      assert_equal Set[], roles(:e).cannot(:all, widgets(:bar))
    end
    assert Authorize::Permission.effective(widgets(:bar), [roles(:e)]).empty?
  end

  test 'cannot does nothing as required' do
    assert_no_difference "Authorize::Permission.count" do
      assert_equal Set[], roles(:e).cannot(:all, widgets(:foo))
    end
    assert Authorize::Permission.effective(widgets(:foo), [roles(:e)]).empty?
  end

  test 'can predicate' do
    assert roles(:c).can?(:read, Widget)
    assert !roles(:c).can?(:read, User)
    assert roles(:user_chris).can?(:all, users(:chris))
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