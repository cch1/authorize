require 'test_helper'

class TrusteeTest < ActiveSupport::TestCase
  fixtures :all

  test 'has primary role' do
    assert_equal roles(:user_chris), users(:chris).role
  end

  test 'create primary role' do
    assert_difference "Authorize::Role.count" do
      assert_difference "Authorize::Role.graph.count" do
        users(:alex).create_role
      end
    end
  end
end