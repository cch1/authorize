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

  test 'should restrict to authorized scope' do
    assert_equal 1, Widget.authorized(users(:pascale).authorization_token, nil).count
    assert_equal 3, Widget.authorized(users(:chris).authorization_token, nil).count
    assert_equal 1, Widget.authorized(users(:chris).authorization_token, :owner).count
  end

  test 'should restrict to authorized scope when authorized generically' do
    assert_equal 3, Widget.authorized(users(:chris).authorization_token, 'overlord').count
  end
  
  test 'should destroy authorization when subject destroyed' do
    assert_difference('Authorization.count', -1) do
      widgets(:foo).destroy
    end
  end
end