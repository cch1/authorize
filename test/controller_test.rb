require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/lib/widgets_controller.rb'

class ControllerTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations
  
  tests WidgetsController
  
  test 'should fail without subject' do
    assert_raises Authorize::CannotObtainModelObject do
      @controller.permit?('owner of w', {:user => users(:chris)})
    end
  end

  test 'should fail without trustee' do
    assert_raises Authorize::CannotObtainUserObject do
      @controller.permit?('owner of w', {:w => widgets(:foo)})
    end
  end

  test 'should represent authorization with boolean' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert @controller.permit?('owner of w', {:user => users(:chris)})
    assert !@controller.permit?('proxy of w', {:user => users(:chris)})
  end

  test 'should represent authorization with block processing or exception' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert_nothing_raised do
      @controller.permit('owner of w', {:user => users(:chris)}) {}
    end
    assert_raises Authorize::AuthorizationError do
      @controller.permit('proxy of w', {:user => users(:chris)}) {}
    end
  end
  
  test 'should find authorizations without identities method' do
    class DegenerateUser < ActiveRecord::Base
      acts_as_trustee
    end
    du = DegenerateUser.create
    du.authorize('steward', widgets(:foo))
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert_nothing_raised do
      @controller.permit('steward of w', {:user => du})
    end
  end
  
  test 'should find user from current_user attribute' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    @controller.instance_variable_set(:@current_user, users(:chris))
    assert @controller.permit?('owner of w')    
  end
end
