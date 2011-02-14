require 'test_helper'
require 'authorize/redis/factory'
require 'set'

class RedisFactoryTest < ActiveSupport::TestCase
  test 'string factory' do
    key, value = 'key', 'value'
    Authorize::Redis::Base.db.expects(:set).with(key, value)
    Authorize::Redis::Factory.build.string(key, value)
  end

  test 'set factory' do
    key, value = 'key', Set['value0', 'value1']
    elements = value.to_a
    Authorize::Redis::Base.db.expects(:sadd).with(key, elements.first)
    Authorize::Redis::Base.db.expects(:sadd).with(key, elements.last)
    Authorize::Redis::Factory.build.set(key, value)
  end

  test 'hash factory' do
    key, value = 'key', {'key0' => 'value0', 'key1' => 'value1'}
    keys = value.keys
    Authorize::Redis::Base.db.expects(:hset).with(key, keys.first, value[keys.first])
    Authorize::Redis::Base.db.expects(:hset).with(key, keys.last, value[keys.last])
    Authorize::Redis::Factory.build.hash(key, value)
  end

  test 'array factory' do
    key, value = 'key', ['value0', 'value1']
    Authorize::Redis::Base.db.expects(:rpush).with(key, value.first).in_sequence
    Authorize::Redis::Base.db.expects(:rpush).with(key, value.last).in_sequence
    Authorize::Redis::Factory.build.array(key, value)
  end

  test 'factory with block' do
    namespace, key, value = :namespace, 'key', 'value'
    Authorize::Redis::Base.db.expects(:set).with([namespace, key].join('::'), value)
    Authorize::Redis::Factory.build(namespace){string(key, value)}
  end

  test 'factory with nested namespace' do
    outer_namespace, inner_namespace, key, value = :outer_namespace, :inner_namespace, 'key', {'key0' => 'value0', 'key1' => 'value1'}
    keys = value.keys
    fullkey = [outer_namespace, inner_namespace, key].join('::')
    Authorize::Redis::Base.db.expects(:hset).with(fullkey, keys.first, value[keys.first])
    Authorize::Redis::Base.db.expects(:hset).with(fullkey, keys.last, value[keys.last])
    Authorize::Redis::Factory.build(outer_namespace){namespace(inner_namespace){hash(key, value)}}
  end

  test 'factory with colliding key and namespace' do
    namespace, ckey, key, value1, value2 = :namespace, 'kns', 'key', 'value1', Set['member0', 'member1']
    elements = value2.to_a
    Authorize::Redis::Base.db.expects(:set).with([namespace, ckey].join('::'), value1)
    Authorize::Redis::Base.db.expects(:sadd).with([namespace, ckey, key].join('::'), elements.first)
    Authorize::Redis::Base.db.expects(:sadd).with([namespace, ckey, key].join('::'), elements.last)
    Authorize::Redis::Factory.build(namespace){string(ckey, value1){set(key, value2)}}
  end

  test 'factory restores namespace after block' do
    ns, key1, value1, key2, value2 = 'namespace', 'key1', 'value1', 'key2', 'value2'
    Authorize::Redis::Base.db.expects(:set).with([ns, key1].join('::'), value1)
    Authorize::Redis::Base.db.expects(:set).with(key2, value2)
    f = Authorize::Redis::Factory.build
    f.namespace(ns){string(key1, value1)}
    f.string(key2, value2)
  end
end