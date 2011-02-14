require 'test_helper'
require 'authorize/redis/fixtures'
require 'set'

class RedisFixtureTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
  end

  test 'fixtures' do
    Authorize::Redis::Fixtures.create_fixtures(Authorize::Redis::Base.db, Pathname.new(fixture_path).join('redis', 'redis.yml'))
    assert_equal 'x', Authorize::Redis::String.new('string').__getobj__
    assert_equal %w(1 2).to_set, Authorize::Redis::Set.new("set").__getobj__
    assert_equal({"a" => "1", "b" => "2"}, Authorize::Redis::Hash.new("hash").__getobj__)
  end
end