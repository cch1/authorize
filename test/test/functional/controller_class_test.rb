require 'test_helper'

class ControllerClassTest < ActionController::TestCase
  fixtures :all

  tests ThingyController

  test 'raise exception when not permitted' do
    @controller.expects(:roles).returns([])
    assert_raises Authorize::AuthorizationError do
      get :index
    end
  end

  test 'rescue response' do
    @controller.expects(:roles).returns([])
    @request.remote_addr = "192.168.1.1"
    get :index
    assert_response :forbidden
  end

  test 'skip filter' do
    assert_nothing_raised do
      get :show
      assert_response :success
    end
  end

  test 'should perform action because of authorization' do
    @controller.expects(:roles).returns([roles(:administrator)])
    assert_nothing_raised do
      get :index
      assert_response :success
    end
  end
end