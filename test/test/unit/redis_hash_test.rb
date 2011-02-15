require 'test_helper'
require 'authorize/redis/factory'

class RedisHashTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Hash.index.clear
    @factory = Authorize::Redis::Factory.new
  end

  test 'hash keys are stringified' do
    h = Authorize::Redis::Hash.new
    h.set("", 'empty')
    h.set(nil, 'nil')
    assert_equal 'nil', h.get(nil)
  end

  test 'merge' do
    h = @factory.hash('h', {'key' => 'a'})
    h.merge('key' => 'A')
    assert_equal 'A', h['key']
  end

  test 'merge with empty hash' do
    h = @factory.hash('h', {'key' => 'a'})
    h.merge({})
    assert_equal 'a', h['key']
  end

  test 'index getter' do
    h = @factory.hash('h', {'key' => 'a'})
    assert_equal h['key'], 'a'
  end
end