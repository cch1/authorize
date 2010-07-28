require 'test_helper'


class ResourceTest < ActiveSupport::TestCase
  fixtures :all

  test 'has permissions' do
    assert_equal Set[permissions(:a_read_foo)], widgets(:foo).permissions.to_set
  end

  test 'permitted scope' do
    assert_equal Set[widgets(:foo), widgets(:bar)], Widget.permitted([roles(:a)], nil).to_set
    assert_equal Set[widgets(:bar)], Widget.permitted([roles(:d)], Authorize::Permission::Mask[:update]).to_set
  end

  test 'permitted scope with class permission' do
    assert_equal Widget.all.to_set, Widget.permitted([roles(:c)], nil).to_set
  end

  test 'permitted scope with global permission' do
    assert_equal Widget.all.to_set, Widget.permitted([roles(:administrator)], nil).to_set
  end

  test 'destroy permissions on destroy' do
    assert_difference('Authorize::Permission.count', -1) do
      widgets(:foo).destroy
    end
  end
end