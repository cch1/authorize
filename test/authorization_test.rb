require File.dirname(__FILE__) + '/test_helper.rb'

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should have valid references' do
    a = authorizations(:chris_foo)
    assert_equal widgets(:foo), a.subject
    assert_equal users(:chris), a.trustee
    assert_equal 'owner', a.role
  end
  
  test 'should identify generic authorizations' do
    assert gas = Authorization.generic_authorizations(users(:chris))
    assert 1, gas.size
  end
  
end
