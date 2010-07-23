require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class PermissionTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :permissions

  test 'create' do
    p = Authorize::Permission.create(:role_id => "X", :resource => widgets(:bar), :mask => 2)
    assert p.valid?, p.errors.full_messages
    assert_equal Set.new([:list, :read]), p.reload.mask
  end

  test 'resource reader' do
    assert_equal widgets(:foo), permissions(:a_read_foo).resource
    assert_equal Widget, permissions(:c_all_widgets).resource
    assert_equal Object, permissions(:b_overlord).resource
  end

  test 'resource writer with instance' do
    p = permissions(:a_list_bar)
    p.resource = widgets(:foo)
    assert_equal Widget.to_s, p[:resource_type]
    assert_equal widgets(:foo).id, p[:resource_id]
    assert p.changed?
  end
    
  test 'resource writer with class' do
    p = permissions(:a_list_bar)
    p.resource = Widget
    assert_equal Widget.to_s, p[:resource_type]
    assert_nil p[:resource_id]
    assert p.changed?
  end

  test 'resource writer with Object' do
    p = permissions(:a_list_bar)
    p.resource = Object
    assert_nil p[:resource_type]
    assert_nil p[:resource_id]
    assert p.changed?
  end

  test 'stringify' do
    assert_kind_of String, permissions(:a_read_foo).to_s
  end

  test 'invalid with missing role' do
    p = Authorize::Permission.new(:role_id => "missing")
    assert !p.valid?
    assert p.errors.on(:role)
  end

  test 'invalid with missing resource' do
    p = Authorize::Permission.new(:resource_type => 'Widget', :resource_id => 0)
    assert !p.valid?
    assert p.errors[:resource]
  end

  test 'mask reader' do
    p = permissions(:a_read_foo)
    assert_equal Set.new([:list, :read]), p.mask
  end

  test 'mask writer with mask' do
    p = permissions(:a_read_foo)
    p.mask # trigger cache
    p.mask = Authorize::Permission::Mask[:delete]
    assert_equal Set[:list, :delete], p.mask
    assert p.mask_changed?
  end

  test 'mask writer with integer' do
    p = permissions(:a_read_foo)
    p.mask # trigger cache
    p.mask = 8
    assert_equal Set[:list, :delete], p.mask
    assert p.mask_changed?
  end

  test 'mask conforms to dirty standards' do
    p = permissions(:a_read_foo)
    p.mask_will_change!
    p.mask << :update
    assert_equal [Authorize::Permission::Mask[:list, :read], Authorize::Permission::Mask[:list, :read, :update]], p.mask_change
  end

  test 'global scope' do
    assert_equal Set[permissions(:b_overlord)], Authorize::Permission.global.to_set
  end

  test 'for scope' do
    assert_equal Set[permissions(:b_overlord)], Authorize::Permission.for(Object).to_set
    assert_equal Set[permissions(:c_all_widgets)], Authorize::Permission.for(Widget).to_set
    assert_equal Set[permissions(:a_read_foo)], Authorize::Permission.for(widgets(:foo)).to_set
  end

  test 'over scope' do
    assert_equal Set[permissions(:b_overlord)], Authorize::Permission.over(Object).to_set
    assert_equal Set[permissions(:b_overlord), permissions(:c_all_widgets)], Authorize::Permission.over(Widget).to_set
    assert_equal Set[permissions(:b_overlord), permissions(:c_all_widgets), permissions(:a_read_foo)], Authorize::Permission.over(widgets(:foo)).to_set
  end

#  test 'should find effective permissions with array of roles' do
#    assert_equal 3, Permission.find_effective(widgets(:bar), nil, ['proxy', 'overlord']).size
#  end
#
#  test 'should find effective permissions with array of role_ids' do
#    assert_equal 2, Permission.find_effective(widgets(:bar), [users(:chris).authorization_role_id, users(:pascale).authorization_role_id], nil).size
#  end
#
#  test 'should find with role_id object' do
#    assert_equal 2, Permission.count(:conditions => {:role_id => users(:chris).authorization_role_id})
#  end
#
#  test 'should restrict to authorized scope' do
#    assert_equal 2, Permission.authorized(users(:chris).authorization_role_id, nil).count
#    assert_equal 1, Permission.authorized(users(:pascale).authorization_role_id, nil).count
#  end
#
#  test 'should restrict to authorized scope including generic permissions' do
#    assert_equal 4, Permission.authorized(users(:chris).authorization_role_id, 'overlord').count
#  end
#
#  test 'should restrict to authorized scope including class permissions' do
#    assert_equal 3, Permission.authorized(users(:alex).authorization_role_id, 'overlord').count
#  end

  test 'effective permissions' do
    assert_equal Set[permissions(:d_update_bar), permissions(:e_delete_bar)], Authorize::Permission.effective(widgets(:bar), %w(d e)).to_set
  end

  test 'effective permission mask' do
    assert_equal Authorize::Permission::Mask[:list, :read, :update, :delete], Authorize::Permission.effective_mask(widgets(:bar), %w(d e))
  end
end