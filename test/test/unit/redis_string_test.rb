require 'test_helper'
require 'authorize/redis/factory'

class RedisStringTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear
    @factory = Authorize::Redis::Factory.new
  end

  test 'valid' do
    s = @factory.string('key', 'value')
    assert s.valid?
  end

  test 'valid when empty' do
    s = Authorize::Redis::String.new
    assert s.valid?
  end

  test 'invalid when key references wrong type' do
    @factory.hash('h', {'key' => 'value'})
    s = Authorize::Redis::String.new('h')
    assert !s.valid?
  end
end