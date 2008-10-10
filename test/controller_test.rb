require File.dirname(__FILE__) + '/test_helper.rb'

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

  test 'should find subject in instance variable' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert_nothing_raised do
      @controller.permit?('owner of w', {:user => users(:chris)})
    end
  end

  test 'should find trustee from current_user method' do
    @controller.instance_variable_set(:@current_user, users(:chris))
    assert_nothing_raised do
      @controller.permit?('owner of w', {:w => widgets(:foo)})
    end
  end

  test 'should find trustee from User.current class attribute' do
    @controller.instance_variable_set(:@current_user, nil)
    User.current = users(:chris)
    assert_nothing_raised do
      @controller.permit?('owner of w', {:w => widgets(:foo)})
    end
  end

  test 'should represent authorization with boolean' do
    assert @controller.permit?('owner of w', {:user => users(:chris), :w => widgets(:foo)})
    assert !@controller.permit?('proxy of w', {:user => users(:chris), :w => widgets(:foo)})
  end

  test 'should represent authorization with block processing or exception' do
    assert_nothing_raised do
      @controller.permit('owner of w', {:user => users(:chris), :w => widgets(:foo)}) {}
    end
    assert_raises Authorize::AuthorizationError do
      @controller.permit('proxy of w', {:user => users(:chris), :w => widgets(:foo)}) {}
    end
  end
  
  test 'should find authorizations without identities method' do
    class ::DegenerateUser < ActiveRecord::Base; acts_as_trustee; end  
    du = DegenerateUser.create
    du.authorize('steward', widgets(:foo))
    assert_nothing_raised do
      @controller.permit('steward of w', {:user => du, :w => widgets(:foo)})
    end
  end

  test 'should parse simple expression' do
    assert @controller.permit?('owner of User or owner or owner of w', {:user => users(:chris), :w => widgets(:foo)})
  end

  test 'should parse complex expression' do
    assert @controller.permit?('owner of w and not (owner of User or owner)', {:user => users(:chris), :w => widgets(:foo)})
  end
end
