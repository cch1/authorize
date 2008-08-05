require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/lib/widgets_controller.rb'

class ControllerTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations
  
  tests WidgetsController
  
  test 'should do something' do
  end
end
