require 'test_helper'

class TrusteeTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
  end

  test 'has primary role' do
    assert_equal roles(:user_chris), users(:chris).role
  end

  test 'create primary role' do
    assert_difference "Authorize::Role.count" do
      assert_difference "Authorize::Role.graph.vertices.count" do
        users(:alex).create_role
      end
    end
  end

  test 'primary role created after create' do
    assert_difference "Authorize::Role.count" do
      assert_difference "Authorize::Role.graph.vertices.count" do
        assert u = User.create, u.errors.full_messages
        assert u.role
      end
    end
  end
end