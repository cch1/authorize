require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class SubjectTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should identify subjections' do
    assert s = widgets(:foo).subjections
    assert_equal 1, s.size
    assert_equal users(:chris).authorization_token, s.first.token
  end

  test 'should know it is subjected' do
    assert widgets(:foo).subjected?('owner', users(:chris))
  end

  test 'should know it is not subjected' do
    assert !widgets(:foo).subjected?('owner', users(:pascale))
    assert !widgets(:foo).subjected?('doorman', users(:chris))
  end

  test 'should be subjectable' do
    widgets(:foo).subject('owner', users(:pascale))
    assert widgets(:foo).subjected?('owner', users(:pascale))
  end

  test 'should be unsubjectable' do
    widgets(:foo).unsubject('owner', users(:chris))
    assert !widgets(:foo).subjected?('owner', users(:chris))
  end

  test 'should be findable when authorized' do
    assert_equal 1, Widget.authorized_find(:all, :tokens => users(:pascale).authorization_tokens).size
    assert_equal 3, Widget.authorized_find(:all, :tokens => users(:chris).authorization_tokens).size
    assert_equal 1, Widget.authorized_find(:all, :tokens => users(:chris).authorization_tokens, :roles => ['owner']).size
  end

  test 'should be findable when authorized generically' do
    assert_equal 3, Widget.authorized_find(:all, :tokens => [users(:chris).authorization_token], :roles => ['overlord']).size
  end

  test 'should be countable when authorized' do
    assert_equal 1, Widget.authorized_count(:all, :tokens => [users(:pascale).authorization_token])
    assert_equal 3, Widget.authorized_count(:all, :tokens => [users(:chris).authorization_token])
    assert_equal 1, Widget.authorized_count(:all, :tokens => [users(:chris).authorization_token], :roles => ['owner'])
  end

  test 'should be countable when authorized generically' do
    assert_equal 3, Widget.authorized_count(:all, :tokens => [users(:chris).authorization_token], :roles => ['overlord'])
  end

  # The authorized_{find, count} methods automatically check User.current.identities when searching for authorized identities.
#  test 'should be findable as User.current when authorized' do
#    User.current = users(:chris)
#    assert_equal 3, Widget.authorized_find(:all).size
#  end
end