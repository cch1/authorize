require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should create' do
    a = Authorization.new(:token => "123", :role => "liege", :subject_type => 'Widget', :subject_id => widgets(:bar).id)
    assert a.valid?
  end

  test 'should not validate with missing token' do
    a = Authorization.new(:token => nil, :role => "liege", :subject_type => 'Widget', :subject_id => widgets(:bar).id)
    assert !a.valid?
    assert a.errors.on(:token)
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

  test 'should scope to generic authorizations' do
    assert_equal({:conditions => {:subject_type => nil, :subject_id => nil}}, Authorization.generic.proxy_options)
    assert 1, Authorization.generic.size
  end

  test 'should have correct conditions with named scopes' do
    assert_equal 1, Authorization.as(%w(proxy overlord)).with(Authorize::Token._build(:chris_authorization_token).to_s).count
  end

  test 'should have correct subject conditions with scope' do
    assert_equal authorizations(:overlord), Authorization.for(nil).first
    assert_equal authorizations(:alex_widget), Authorization.for(Widget).first
    assert_equal authorizations(:chris_foo), Authorization.for(widgets(:foo)).first
  end

  test 'should find effective authorizations with array of roles' do
    assert_equal 3, Authorization.find_effective(widgets(:bar), nil, ['proxy', 'overlord']).size
  end

  test 'should find effective authorizations with array of tokens' do
    assert_equal 2, Authorization.find_effective(widgets(:bar), [users(:chris).authorization_token, users(:pascale).authorization_token], nil).size
  end

  test 'should find with token object' do
    token = Authorize::Token._build(:chris_authorization_token)
    assert_equal 2, Authorization.count(:conditions => {:token => token})
  end

  test 'should restrict to authorized scope' do
    assert_equal 2, Authorization.authorized(users(:chris).authorization_token, nil).count
    assert_equal 1, Authorization.authorized(users(:pascale).authorization_token, nil).count
  end
  
  test 'should restrict to authorized scope including generic authorizations' do
    assert_equal 4, Authorization.authorized(users(:chris).authorization_token, 'overlord').count
  end

  test 'should restrict to authorized scope including class authorizations' do
    assert_equal 3, Authorization.authorized(users(:alex).authorization_token, 'overlord').count
  end
  
  test 'should find effective authorizations' do
    assert_equal 1, Authorization.find_effective(widgets(:foo), nil, 'owner').size
    assert Authorization.find_effective(widgets(:bar), nil, 'owner').empty?
  end

  test 'should find effective authorizations for class' do
    assert_equal 2, Authorization.find_effective(Widget).size
  end

  test 'should find effective global authorizations' do
    assert_equal 1, Authorization.over(nil).size
    assert_equal 1, Authorization.find_effective(nil).size
  end
end