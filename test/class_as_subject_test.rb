require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class ClassAsSubjectTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should identify subjections' do
    assert s = Widget.subjections
    assert_equal 1, s.size
    assert_equal users(:alex).authorization_token, s.first.token
  end

  test 'should know it is subjected' do
    assert Widget.subjected?('overlord', users(:alex))
  end

  test 'should know it is not subjected' do
    assert !Widget.subjected?('overlord', users(:pascale))
    assert !Widget.subjected?('doorman', users(:alex))
  end

  test 'should be subjectable' do
    Widget.subject('owner', users(:pascale))
    assert Widget.subjected?('owner', users(:pascale))
  end

  test 'should be unsubjectable' do
    Widget.unsubject('overlord', users(:alex))
    assert !Widget.subjected?('overlord', users(:alex))
  end
end