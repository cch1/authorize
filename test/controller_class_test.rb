require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class ControllerClassTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations
  
  tests ThingyController
  
  test 'should not perform action' do
    @controller.instance_variable_set(:@current_user, users(:pascale).authorization_token)
    assert_raises Authorize::AuthorizationError do
      get :index
    end
  end

  test 'should perform action' do
    @controller.instance_variable_set(:@current_user, users(:chris).authorization_token)
    assert_nothing_raised do
      get :index
      assert_response :success
    end
  end
end
