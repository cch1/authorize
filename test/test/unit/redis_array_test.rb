require 'test_helper'

class RedisArrayTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Array.index.clear
    @factory = Authorize::Redis::Factory.new
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

  test 'index' do
    a = @factory.array('test', %w(ant bear cat))
    assert_equal "cat", a[2]
  end

  test 'range index' do
    a = @factory.array('test', %w(ant bear cat))
    assert_equal %w(bear cat), a[1..2]
  end

  test 'to_a' do
    a = @factory.array('test', %w(ant bear cat))
    assert_equal %w(ant bear cat), a.to_a
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

  test 'valid' do
    a = @factory.array('a', ['a'])
    assert a.valid?
  end

  test 'valid when empty' do
    a = Authorize::Redis::Array.new
    assert a.valid?
  end
end