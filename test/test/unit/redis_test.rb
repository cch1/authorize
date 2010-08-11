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
    b = v0.get
    assert_equal a, b
  end

  # Do Redis objects stored and retrieved as values honor the coherency contract?
  # This is a test of the strict serializability of Redis objects and the serialization of values.
  test 'serialization as value' do
    a = Authorize::Redis::Set.new
    a.add(1);a.add(2);a.add(3)
    v0 = Authorize::Redis::Value.new
    v0.set(a)
    b = v0.get
    assert_same a, b
  end

# --Hash--------------------------------------------------------------------

  test 'hash keys are serialized' do
    h = Authorize::Redis::Hash.new
    h.set(nil, 'nil')
    h.set("", 'empty')
    assert_equal 'nil', h.get(nil)
  end
end