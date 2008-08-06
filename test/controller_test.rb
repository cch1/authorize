require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/lib/widgets_controller.rb'

class ControllerTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations
  
  tests WidgetsController
  
  test 'should indicate authorization with predicate' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert @controller.permit?('owner of w', {:user => users(:chris)})
    assert !@controller.permit?('proxy of w', {:user => users(:chris)})
  end

  test 'should indicate authorization with block processing' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert_nothing_raised do
      @controller.permit('owner of w', {:user => users(:chris)}) {}
    end
    assert_raises Authorize::AuthorizationError do
      @controller.permit('proxy of w', {:user => users(:chris)}) {}
    end
  end
end
