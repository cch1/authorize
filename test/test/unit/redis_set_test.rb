require 'test_helper'

class RedisSetTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    @factory = Authorize::Redis::Factory.new
  end

  test 'add member' do
    sid, member = 'set_id', 'member'
    Authorize::Redis::Set.db.expects(:sadd).with(sid, member)
    s = Authorize::Redis::Set.load(sid)
    s.add(member)
  end

  test 'delete member' do
    sid, member = 'set_id', 'member'
    Authorize::Redis::Set.db.expects(:srem).with(sid, member)
    s = Authorize::Redis::Set.load(sid)
    s.delete(member)
  end

  test 'load proxy from store' do
    sid, member = 'set_id', 'member'
    Authorize::Redis::Set.db.expects(:smembers).with(sid).returns([member])
    s = Authorize::Redis::Set.load(sid)
    assert_equal 1, s.length
  end

  test 'enumerable' do
    s = Authorize::Redis::Set.new
    s.add(23);s.add(27)
    assert_equal "2327", s.inject{|m, e| m + e}
  end

  test 'valid' do
    s = @factory.set('h', Set['a'])
    assert s.valid?
  end

  test 'valid when empty' do
    s = Authorize::Redis::Set.new
    assert s.valid?
  end

  test 'include' do
    s = @factory.set('h', Set['a'])
    assert s.include?('a')
  end

  test 'sample single' do
    s = @factory.set('h', Set['a', 'b'])
    assert s.sample
  end

  test 'sample multiple' do
    # depends on Ruby 1.9
#    s = @factory.set('h', Set['a', 'b'])
#    assert_equal Set['a', 'b'], s.sample(3)
  end

  test 'first multiple' do
    s = @factory.set('h', Set['a', 'b'])
    assert_equal ['a', 'b'].to_set, s.first(3).to_set
  end
end