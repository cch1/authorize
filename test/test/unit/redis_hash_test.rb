require 'test_helper'

class RedisHashTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Hash.index.clear
  end

  test 'hash keys are stringified' do
    h = Authorize::Redis::Hash.new
    h.set("", 'empty')
    h.set(nil, 'nil')
    assert_equal 'nil', h.get(nil)
  end
end