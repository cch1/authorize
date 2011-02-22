require 'test_helper'
require 'authorize/redis/model_reference'

class RedisModelReferenceTest < ActiveSupport::TestCase
  include Authorize::Redis

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Redis::Factory.build('X') do
      string('reference1', subordinate_key('target'))
      hash('target', {'key' => 'value'})
      string('reference2', subordinate_key('missingtarget'))
    end
  end

  test 'set reference' do
    key = 'X::reference0'
    h = Authorize::Redis::Hash.load('X::target')
    Authorize::Redis::String.db.expects(:set).with(key, h.id).returns(h.id)
    assert ModelReference.set_reference(key, h)
  end

  test 'load reference' do
    assert_kind_of Authorize::Redis::Hash, ModelReference.load_reference('X::reference1', Authorize::Redis::Hash)
  end

  test 'load reference with invalid reference' do
    assert_nil ModelReference.load_reference('X::missing_reference', Authorize::Redis::Hash)
  end
end