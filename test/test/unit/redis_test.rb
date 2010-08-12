require 'test_helper'

class RedisTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Base.db.flushdb
    Authorize::Redis::Value.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
  end

  test 'coherent identity from cache' do
    assert o0 = Authorize::Redis::Value.new('xyx')
    assert o1 = Authorize::Redis::Value.new('xyx')
    assert_same o0, o1
  end

  uses_mocha "track initialization process" do
    test 'initialize semantics' do
      Authorize::Redis::Value.any_instance.expects(:initialize).once
      Authorize::Redis::Value.any_instance.expects(:reloaded).never
      Authorize::Redis::Value.new('new_key')
    end

    test 'reload semantics' do
      Authorize::Redis::Value.db.set('x', nil)
      Authorize::Redis::Value.any_instance.expects(:reloaded)
      Authorize::Redis::Value.any_instance.expects(:initialize).never
      assert val1 = Authorize::Redis::Value.new('x')
    end
  end

  # Can Redis objects be serialized according to conventional contracts?
  test 'serializability' do
    v0 = Authorize::Redis::Value.new
    v0.set("Hi Mom")
    assert_instance_of String, s = Marshal.dump(v0)
    assert_instance_of Authorize::Redis::Value, v1 = Marshal.load(s)
    assert_equal v0, v1
  end

  # Do serialized and re-hyrdrated Redis objects honor the strict coherent identity contract?
  test 'coherency through serialization' do
    v0 = Authorize::Redis::Value.new
    v0.set("Hi Mom")
    v1 = Marshal.load(Marshal.dump(v0))
    assert_same v0, v1
  end

  # Are serializable objects properly stored and retrieved?
  test 'serialization of values' do
    a = [1,2,3]
    v0 = Authorize::Redis::Value.new
    v0.set(a)
    b = v0.__getobj__
    assert_equal a, b
  end

  # Do Redis objects stored and retrieved as values honor the coherency contract?
  # This is a test of the strict serializability of Redis objects and the serialization of values.
  test 'serialization as value' do
    a = Authorize::Redis::Value.new
    a.set(1)
    v0 = Authorize::Redis::Value.new
    v0.set(a)
    b = v0.__getobj__
    assert_same a, b
  end

# --Value-------------------------------------------------------------------
  test 'proxy to native object' do
    v = Authorize::Redis::Value.new
    v.set(23)
    assert_equal 25, v + 2
  end

  test 'proxy is frozen' do
    v = Authorize::Redis::Value.new
    v.set("ABC")
    assert_raises TypeError do
      v << "DEF"
    end
  end

# --Set---------------------------------------------------------------------
  test 'proxy to native set' do
    s = Authorize::Redis::Set.new
    s.add(23)
    assert_equal 1, s.length
  end

  test 'enumerable' do
    s = Authorize::Redis::Set.new
    s.add(23);s.add(27)
    assert_equal 50, s.inject{|m, e| m + e}
  end
# --Hash--------------------------------------------------------------------
  test 'hash keys are serialized' do
    h = Authorize::Redis::Hash.new
    h.set(nil, 'nil')
    h.set("", 'empty')
    assert_equal 'nil', h.get(nil)
  end
end