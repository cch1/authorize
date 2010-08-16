require 'test_helper'

class RedisTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::Base.db.flushdb
    Authorize::Redis::Value.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
  end

  test 'fixtures' do
    redis_fixtures(Authorize::Redis::Base.db, Pathname.new(fixture_path).join('redis', 'redis.yml'))
    assert_equal 'x', Authorize::Redis::Value.new('x').__getobj__
    assert_equal Set[1,2], Authorize::Redis::Set.new("set").__getobj__
    assert_equal({:a => 1, :b => 2}, Authorize::Redis::Hash.new("hash").__getobj__)
    assert_equal Set[Authorize::Redis::Value.load('x')], Authorize::Redis::Set.new("value_set").__getobj__
  end

  test 'identity' do
    assert o0 = Authorize::Redis::Value.new
    assert o1 = Authorize::Redis::Value.new
    assert_not_same o0, o1
  end

  test 'equality' do
    assert o0 = Authorize::Redis::Value.new
    o0.set('xyx')
    assert o1 = Authorize::Redis::Value.new
    o1.set('xyx')
    assert_equal o0, o1
  end

  # This test ensures that different object instances mapping to the same database value(s) are
  # considered identical in the context of membership within a collection (Hash, Set, Array, etc.).
  test 'hash equality' do
    assert o0 = Authorize::Redis::Value.new('A')
    o0.set('xyx')
    assert o1 = Authorize::Redis::Value.new('A')
    o1.set('xyx')
    assert o0.eql?(o1)
    assert_equal o0.hash, o1.hash
  end

  uses_mocha "track initialization process" do
    test 'initialize semantics' do
      Authorize::Redis::Value.any_instance.expects(:initialize).once
      Authorize::Redis::Value.any_instance.expects(:reload).never
      Authorize::Redis::Value.new('new_key')
    end

    test 'reload semantics' do
      Authorize::Redis::Value.db.set('x', nil)
      Authorize::Redis::Value.any_instance.expects(:reload)
      Authorize::Redis::Value.any_instance.expects(:initialize).never
      assert val1 = Authorize::Redis::Value.load('x')
    end
  end

  # Can Redis objects be serialized according to conventional Marshal contracts?
  test 'serializability with Marshal' do
    v0 = Authorize::Redis::Value.new
    v0.set("Hi Mom")
    assert_instance_of String, s = Marshal.dump(v0)
    assert_instance_of Authorize::Redis::Value, v1 = Marshal.load(s)
    assert_equal v0, v1
  end

  # Can Redis objects be serialized according to conventional YAML contracts?
  test 'serializability with YAML' do
    v0 = Authorize::Redis::Value.new
    v0.set("Hi Mom")
    assert_instance_of String, s = YAML.dump(v0)
    assert_instance_of Authorize::Redis::Value, v1 = YAML.load(s)
    assert_equal v0, v1
  end

  # Can Redis objects be serialized according to conventional YAML contracts?
  test 'serializability with YAML as set' do
    v0 = Authorize::Graph::Vertex.new
    set0 = Set[v0]
    assert_instance_of String, s = YAML.dump(set0)
    assert_instance_of Set, set1 = YAML.load(s)
    assert_instance_of Authorize::Graph::Vertex, v1 = set1.first
    assert_equal v0, v1
  end

  # Do serialized and re-hyrdrated Redis objects honor the strict identity contract?
  test 'serialization' do
    v0 = Authorize::Redis::Value.new
    v0.set("Hi Mom")
    v1 = Marshal.load(Marshal.dump(v0))
    assert v0.eql?(v1)
    assert_equal v0, v1
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
    assert a.eql?(b)
    assert_equal a, b
  end

  test 'exist' do
    assert !Authorize::Redis::Value.exists?('newkey')
    Authorize::Redis::Value.new("newkey").set(1)
    assert Authorize::Redis::Value.exists?('newkey')
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