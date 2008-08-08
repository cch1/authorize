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
  
  test 'should identify effective authorizations' do
    assert_equal 1, Authorization.find_effective(widgets(:foo), nil, 'owner').size
    assert Authorization.find_effective(widgets(:bar), nil, 'owner').empty?
  end

  test 'should identify effective authorizations with array of roles' do
    assert_equal 2, Authorization.find_effective(widgets(:bar), nil, ['proxy', 'overlord']).size
  end

  test 'should identify effective authorizations with array of trustees' do
    assert_equal 2, Authorization.find_effective(widgets(:bar), [users(:chris), users(:pascale)], nil).size
  end
end
