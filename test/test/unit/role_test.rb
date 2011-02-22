require 'test_helper'
require 'authorize/graph/fixtures'

class RoleTest < ActiveSupport::TestCase

  fixtures :all

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::DirectedGraph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    Authorize::Graph::Fixtures.create_fixtures
  end

  test 'new global' do
    assert r = Authorize::Role.new(:name => 'Master of the Universe', :relation => 'MST')
    assert r.valid?
  end

  test 'new' do
    assert r = Authorize::Role.new(:name => 'friend of %s', :resource => users(:chris), :relation => 'FRN')
    assert r.valid?
  end

  test 'create' do
    Authorize::Graph::Graph.db.expects(:set).with(regexp_matches(/Authorize::Role::vertices::\d*::_/), nil).returns(true)
    assert_difference 'Authorize::Role.count' do
      r = Authorize::Role.create(:name => 'friend of %s', :resource => users(:chris), :relation => 'FRN')
    end
  end

  test 'new identity' do
    assert r = Authorize::Role.new(:resource => users(:pascale))
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

  test 'relation scope' do
    assert_equal Set[roles(:e)], Authorize::Role.as('HSK').to_set
  end

  test 'may adds modes to existing permission' do
    p = permissions(:e_delete_bar)
    mask = p.mask + [:update]
    assert_equal mask, roles(:e).may(:update, widgets(:bar))
    assert p.reload.mask.include?(:update)
  end

  test 'may_not removes modes from existing permission' do
    p = permissions(:e_delete_bar)
    mask = p.mask - [:delete]
    assert_equal mask , roles(:e).may_not(:delete, widgets(:bar))
    assert !p.reload.mask.include?(:update)
  end

  test 'may inserts permission as required' do
    assert_difference "Authorize::Permission.count", 1 do
      assert_equal Set[:list, :update], roles(:e).may(:update, widgets(:foo))
    end
    assert !Authorize::Permission.over(widgets(:foo)).as([roles(:e)]).empty?
  end

  test 'may_not deletes permission as required' do
    assert_difference "Authorize::Permission.count", -1 do
      assert_equal Set[], roles(:e).may_not(:all, widgets(:bar))
    end
    assert Authorize::Permission.over(widgets(:bar)).as([roles(:e)]).empty?
  end

  test 'may_not does nothing as required' do
    assert_no_difference "Authorize::Permission.count" do
      assert_equal Set[], roles(:e).may_not(:all, widgets(:foo))
    end
    assert Authorize::Permission.over(widgets(:foo)).as([roles(:e)]).empty?
  end

  test 'may predicate' do
    assert roles(:c).may?(:read, Widget)
    assert !roles(:c).may?(:read, User)
    assert roles(:user_chris).may?(:all, users(:chris))
  end

  test 'may_not predicate' do
    assert roles(:c).may_not?(:read, User)
    assert !roles(:c).may_not?(:read, Widget)
    assert roles(:user_chris).may_not?(:all, users(:alex))
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
    assert_equal Set[roles(:registered_users), roles(:public)], roles(:user_chris).descendants
  end

  test 'link' do
    assert !roles(:user_chris).descendants.include?(roles(:administrator))
    assert_kind_of Authorize::Graph::Edge, edge = roles(:user_chris).link(roles(:administrator))
    assert roles(:user_chris).descendants.include?(roles(:administrator))
    assert Authorize::Role.graph.edge_ids.include?(edge.id)
  end

  test 'reuse existing edge on redundant link' do
    Authorize::Graph::Edge.expects(:new).never
    roles(:user_chris).link(roles(:registered_users))
  end

  test 'unlink' do
    assert roles(:user_chris).descendants.include?(roles(:registered_users))
    assert_kind_of Authorize::Graph::Edge, edge = roles(:user_chris).unlink(roles(:registered_users))
    assert !roles(:user_chris).descendants.include?(roles(:registered_users))
    assert !Authorize::Role.graph.edge_ids.include?(edge.id)
  end

  test 'destroy' do
    roles(:user_chris).vertex.expects(:destroy).returns(true)
    roles(:user_chris).destroy
  end
end