require File.dirname(__FILE__) + '/test_helper.rb'

class SubjectTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should identify subjections' do
    assert s = widgets(:foo).subjections
    assert_equal 1, s.size
    assert_equal users(:chris), s.first.trustee
  end
  
  test 'should know it is subjected' do
    assert widgets(:foo).subjected?('owner', users(:chris))
  end

  test 'should know it is not subjected' do
    assert !widgets(:foo).subjected?('owner', users(:pascale))
    assert !widgets(:foo).subjected?('doorman', users(:chris))
  end

  test 'should be subjectable' do
    widgets(:foo).subject('owner', users(:pascale))
    assert widgets(:foo).subjected?('owner', users(:pascale))
  end

  test 'should be unsubjectable' do
    widgets(:foo).unsubject('owner', users(:chris))
    assert !widgets(:foo).subjected?('owner', users(:chris))
  end
end
