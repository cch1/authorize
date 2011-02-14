require 'test_helper'

class RedisArrayTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Array.index.clear
  end

  test 'push element' do
    aid, element = 'array_id', 'element'
    Authorize::Redis::Array.db.expects(:rpush).with(aid, element)
    s = Authorize::Redis::Array.load(aid)
    s.push(element)
  end

  test 'delete element' do
    aid, element = 'array_id', 'element'
    Authorize::Redis::Array.db.expects(:rpop).with(aid)
    s = Authorize::Redis::Array.load(aid)
    s.pop
  end

  test 'load proxy from store' do
    aid, element = 'array_id', 'element'
    Authorize::Redis::Array.db.expects(:lrange).with(aid, 0, -1).returns([element])
    s = Authorize::Redis::Array.load(aid)
    assert_equal 1, s.length
  end

  test 'enumerable' do
    s = Authorize::Redis::Array.new
    s.push(23);s.push(27)
    assert_equal "2327", s.inject{|m, e| m + e}
  end
end