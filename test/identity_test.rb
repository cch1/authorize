require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class IdentityTest < ActiveSupport::TestCase
  fixtures :all

  test 'should implement has_role? dynamic predicate' do
    assert widgets(:foo).has_owners?
    assert !widgets(:foo).has_fans?
  end

  test 'should implement has_role dynamic finders' do
    assert owners = widgets(:foo).has_owners
    assert_equal 1, owners.size
    assert fans = widgets(:foo).has_fans
    assert_equal 0, fans.size
  end

  test 'should implement is_role? dynamic predicate' do
    assert users(:chris).is_overlord?
    assert !users(:chris).is_owner?
    assert users(:chris).is_owner_of?(widgets(:foo))
    assert !users(:chris).is_overlord_of?(widgets(:foo))
  end

  test 'should implement is_role dynamic creator' do
    assert users(:chris).is_advocate
    assert_equal 1, Authorization.as('advocate').count
  end

  test 'should implement is_role_of_what dynamic finders' do
    assert minions = users(:alex).is_overlord_of_what
    assert_equal 1, minions.size
    assert minions.include?(Widget)
  end
end