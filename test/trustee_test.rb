require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class TrusteeTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should identify permissions' do
    assert ps = users(:chris).permissions
    assert_equal 2, ps.size
    assert ps.any?{|p| p.subject == widgets(:foo) }
  end
  
  test 'should know it is authorized' do
    assert users(:chris).authorized?('owner', widgets(:foo))
  end

  test 'should know it is not authorized' do
    assert !users(:chris).authorized?('owner', widgets(:bar))
    assert !users(:chris).authorized?('doorman', widgets(:foo))
  end

  test 'should be authorizable' do
    users(:chris).authorize('owner',widgets(:bar))
    assert users(:chris).authorized?('owner', widgets(:bar))
  end

  test 'should be unauthorizable' do
    users(:chris).unauthorize('owner', widgets(:foo))
    assert !users(:chris).authorized?('owner', widgets(:foo))
  end

  test 'should know it is not authorized over a class' do
    assert !users(:chris).authorized?('owner', Widget)
  end

  test 'should be authorizable over a class' do
    users(:chris).authorize('master', Widget)
    assert users(:chris).authorized?('master', Widget)
  end

  test 'should know it is authorized generically' do
    assert users(:chris).authorized?('overlord')
  end

  test 'should be unauthorizable generically' do
    users(:chris).unauthorize('overlord')
    assert !users(:chris).authorized?('overlord')
  end
  
  test 'should authorize degenerate user' do
    du = DegenerateUser.new
    assert_difference("Authorization.count", 1) do
      du.authorize('steward', widgets(:foo))
      assert du.authorized?('steward', widgets(:foo))
    end
  end
end
