require 'test_helper'

#require 'authorize/role'

class RoleTest < ActiveSupport::TestCase
  fixtures :all

  test 'new global' do
    assert r = Authorize::Role.new(:name => 'Master of the Universe')
    assert r.valid?
  end

  test 'new' do
    assert r = Authorize::Role.new(:name => 'friend of %s', :_resource => users(:chris))
    assert r.valid?
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
end