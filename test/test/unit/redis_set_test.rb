require 'test_helper'

class RedisSetTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
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
end