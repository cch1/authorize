require 'test_helper'
require 'authorize/graph/fixtures'

class ControllerTest < ActionController::TestCase
  fixtures :all

  tests WidgetsController

  def setup
    ::Authorize::Graph::Fixtures.create_fixtures
  end

  test 'predicate not stuck on false when permitted' do
    assert @controller.permit?({:list => widgets(:foo)}, {:roles => [roles(:administrator)]})
  end

  test 'predicate not stuck on true when not permitted' do
    assert !@controller.permit?({:all => Widget}, {:roles => []})
  end

  test 'query controller for default roles' do
    @controller.expects(:roles).returns([roles(:administrator)])
    @controller.permit?(:update => widgets(:foo))
  end

  test 'yields to block when permitted' do
    sentinel = mock('sentinel', {:trip! => true})
    @controller.permit({:list => widgets(:foo)}, {:roles => [roles(:administrator)]}) {sentinel.trip!}
  end

  test 'calls handler and does not yield to block when not permitted' do
    sentinel = mock('sentinel')
    @controller.expects(:handle_authorization_failure).returns(true)
    @controller.permit({:all => Widget}, {:roles => []}) {sentinel.trip!}
  end

  test 'handler raises authorization exception' do
    assert_raises Authorize::AuthorizationError do
      @controller.permit({:all => Widget}, {:roles => []}) {sentinel.trip!}
    end
  end

  test 'mutiple authorization hash pairs' do
    assert @controller.permit?({:list => widgets(:foo), :update => users(:chris)}, {:roles => [roles(:user_chris)]})
  end
end