require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/lib/thingy_controller.rb'

class ControllerClassTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations
  
  tests ThingyController
  
  test 'should not perform action' do
    @controller.instance_variable_set(:@current_user, users(:pascale))
    assert_raises Authorize::AuthorizationError do
      get :index
    end
  end

  test 'should perform action' do
    @controller.instance_variable_set(:@current_user, users(:chris))
    assert_nothing_raised do
      get :index
      assert_response :success
    end
  end
end
