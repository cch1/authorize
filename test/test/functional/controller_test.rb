require 'test_helper'

class ControllerTest < ActionController::TestCase
  fixtures :users, :widgets, :authorizations

  tests WidgetsController

  test 'should fail without subject' do
    assert_raises Authorize::CannotObtainModelObject do
      @controller.permit?('owner of w', {:token => users(:chris)})
    end
  end

  test 'should not fail with no tokens' do
    assert_nothing_raised do
      assert !@controller.permit?('owner of w', {:w => widgets(:foo)})
    end
  end

  uses_mocha "mock an exception fetching auth tokens" do
    test 'should raise exception if tokens indeterminate' do
      @controller.stubs(:authorization_tokens).raises(RuntimeError)
      assert_raises Authorize::CannotObtainTokens do
        @controller.permit?('owner of w', {:w => widgets(:foo)})
      end
    end
  end

  test 'should find subject in instance variable' do
    @controller.instance_variable_set(:@w, widgets(:foo))
    assert_nothing_raised do
      @controller.permit?('owner of w', {:token => users(:chris)})
    end
  end

  test 'should treat nil subject as global permission check' do
    assert_nothing_raised do
      assert !@controller.permit?('owner of w', {:token => users(:chris), :w => nil})
    end
  end

  test 'should find trustee from authorization_tokens method' do
    @controller.authorization_tokens << users(:chris).authorization_token
    assert_nothing_raised do
      @controller.permit?('owner of w', {:w => widgets(:foo)})
    end
  end

  test 'should represent authorization with boolean' do
    assert @controller.permit?('owner of w', {:token => users(:chris).authorization_token, :w => widgets(:foo)})
    assert !@controller.permit?('proxy of w', {:token => users(:chris).authorization_token, :w => widgets(:foo)})
  end

  test 'should represent authorization with block processing or exception' do
    assert_nothing_raised do
      @controller.permit('owner of w', {:token => users(:chris).authorization_token, :w => widgets(:foo)}) {}
    end
    assert_raises Authorize::AuthorizationError do
      @controller.permit('proxy of w', {:token => users(:chris).authorization_token, :w => widgets(:foo)}) {}
    end
  end

  test 'should find authorizations without identities method' do
    du = DegenerateUser.new
    du.authorize('steward', widgets(:foo))
    assert @controller.permit?('steward of w', {:token => du.authorization_token, :w => widgets(:foo)})
  end

  test 'should parse simple expression' do
    assert @controller.permit?('owner of User or owner or owner of w', {:token => users(:chris).authorization_token, :w => widgets(:foo)})
  end

  test 'should parse complex expression' do
    assert @controller.permit?('owner of w and not (owner of User or owner)', {:token => users(:chris).authorization_token, :w => widgets(:foo)})
  end
end
