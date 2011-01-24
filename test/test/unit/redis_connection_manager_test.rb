require 'test_helper'

class RedisConnectionManagerTest < ActiveSupport::TestCase
  extend Authorize::Redis

  def setup
    @connection = stub('connection')
    @specification = stub('specification')
  end

  test 'acquire_connection connects' do
    manager = Authorize::Redis::ConnectionManager.new(@specification, :size => 1)
    @specification.expects(:connect! => @connection)
    assert_same @connection, manager.acquire_connection
  end

  test 'acquire_connection is idempotent for a given thread' do
    manager = Authorize::Redis::ConnectionManager.new(@specification, :size => 1)
    @specification.expects(:connect!).once.returns(@connection)
    c0 = manager.acquire_connection
    c1 = manager.acquire_connection
    assert_same c0, c1
  end

  test 'acquire connection blocks when full' do
    begin
      manager = Authorize::Redis::ConnectionManager.new(@specification, :size => 1)
      @specification.expects(:connect! => @connection)
      c = manager.acquire_connection
      t = Thread.new(manager) {|m| m.acquire_connection}
      t.run
      assert_equal 'sleep', t.status
      manager.release_connection
      t.run
      assert_equal false, t.status # Thread has run to completion.
    ensure
      t.exit
    end
  end

  test 'release connection' do
    manager = Authorize::Redis::ConnectionManager.new(@specification, :size => 1)
    @specification.expects(:connect! => @connection)
    c = manager.acquire_connection
    manager.release_connection
    assert manager.pool.include?(c)
  end

  test 'connection is unique per thread' do
    manager = Authorize::Redis::ConnectionManager.new(@specification)
    @specification.expects(:connect!).once.returns(@connection)
    2.times { manager.connection }
  end
end