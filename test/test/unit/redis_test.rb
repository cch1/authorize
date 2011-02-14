require 'test_helper'

class RedisTest < ActiveSupport::TestCase
  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
  end

  test 'identity' do
    assert o0 = Authorize::Redis::String.new
    assert o1 = Authorize::Redis::String.new
    assert_not_same o0, o1
  end

  test 'equality' do
    assert o0 = Authorize::Redis::String.new
    o0.set('xyx')
    assert o1 = Authorize::Redis::String.new
    o1.set('xyx')
    assert_equal o0, o1
  end

  # This test ensures that different object instances mapping to the same database value(s) are
  # considered identical in the context of membership within a collection (Hash, Set, Array, etc.).
  test 'hash equality' do
    assert o0 = Authorize::Redis::String.new('A')
    o0.set('xyx')
    assert o1 = Authorize::Redis::String.new('A')
    o1.set('xyx')
    assert o0.eql?(o1)
    assert_equal o0.hash, o1.hash
  end

  uses_mocha "track initialization process" do
    test 'initialize semantics' do
      Authorize::Redis::String.any_instance.expects(:initialize).once
      Authorize::Redis::String.any_instance.expects(:reload).never
      Authorize::Redis::String.new('x') # Even with an existing key...
    end

    test 'reload semantics' do
      Authorize::Redis::String.any_instance.expects(:reload)
      Authorize::Redis::String.any_instance.expects(:initialize).never
      assert val1 = Authorize::Redis::String.load('new_key') # Even with a new key
    end
  end

  # Can Redis objects be serialized according to conventional Marshal contracts?
  test 'serializability with Marshal' do
    v0 = Authorize::Redis::String.new
    v0.set("Hi Mom")
    assert_instance_of String, s = Marshal.dump(v0)
    assert_instance_of Authorize::Redis::String, v1 = Marshal.load(s)
    assert_equal v0, v1
  end

  # Can Redis objects be serialized according to conventional YAML contracts?
  test 'serializability with YAML' do
    v0 = Authorize::Redis::String.new
    v0.set("Hi Mom")
    assert_instance_of String, s = YAML.dump(v0)
    assert_instance_of Authorize::Redis::String, v1 = YAML.load(s)
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
    v0 = Authorize::Redis::String.new
    v0.set("Hi Mom")
    v1 = Marshal.load(Marshal.dump(v0))
    assert v0.eql?(v1)
    assert_equal v0, v1
  end

  test 'exist' do
    assert !Authorize::Redis::String.exists?('newkey')
    Authorize::Redis::String.new("newkey").set(1)
    assert Authorize::Redis::String.exists?('newkey')
  end

# --String-------------------------------------------------------------------
  test 'proxy to native String' do
    v = Authorize::Redis::String.new
    v.set(23)
    assert_equal "232", v + "2"
  end

  test 'proxy is frozen' do
    v = Authorize::Redis::String.new
    v.set("ABC")
    assert_raises TypeError do
      v << "DEF"
    end
  end

# --Hash--------------------------------------------------------------------
  test 'hash keys are stringified' do
    h = Authorize::Redis::Hash.new
    h.set("", 'empty')
    h.set(nil, 'nil')
    assert_equal 'nil', h.get(nil)
  end
end