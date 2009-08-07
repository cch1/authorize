require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should create' do
    a = Authorization.new(:token => "123", :role => "liege", :subject_type => 'Widget', :subject_id => widgets(:bar).id)
    assert a.valid?
  end

  test 'should not validate with invalid subject_id' do
    a = Authorization.new(:token => "123", :role => "liege", :subject_type => 'Widget', :subject_id => 1)
    assert !a.valid?
    assert a.errors[:subject]
  end

  test 'should have valid references' do
    a = authorizations(:chris_foo)
    assert_equal widgets(:foo), a.subject
    assert_equal users(:chris).authorization_token, a.token
    assert_equal 'owner', a.role
  end
  
  test 'should find generic authorizations' do
    assert gas = Authorization.generic_authorizations(users(:chris))
    assert 1, gas.size
  end
  
  test 'should find effective authorizations with array of roles' do
    assert_equal 3, Authorization.find_effective(widgets(:bar), nil, ['proxy', 'overlord']).size
  end

  test 'should find effective authorizations with array of tokens' do
    assert_equal 2, Authorization.find_effective(widgets(:bar), [users(:chris), users(:pascale)], nil).size
  end
  
  test 'should find authorized authorizations' do
    assert_equal 2, Authorization.authorized_find(:all, :tokens => users(:chris)).size
    assert_equal 1, Authorization.authorized_find(:all, :tokens => users(:pascale)).size
  end
  
  test 'should find authorized authorizations including generic authorizations' do
    assert_equal 4, Authorization.authorized_find(:all, :tokens => users(:chris), :roles => 'overlord').size
  end

  test 'should find authorized authorizations including class authorizations' do
    assert_equal 3, Authorization.authorized_find(:all, :tokens => users(:alex), :roles => 'overlord').size
  end
  
  test 'should find effective authorizations' do
    assert_equal 1, Authorization.find_effective(widgets(:foo), nil, 'owner').size
    assert Authorization.find_effective(widgets(:bar), nil, 'owner').empty?
  end

  test 'should find effective authorizations for class' do
    assert_equal 2, Authorization.find_effective(Widget).size
  end

  test 'should find effective global authorizations' do
    assert_equal 1, Authorization.find_effective().size
  end
end
