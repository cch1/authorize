require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class TokenTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should generate masked key' do
    assert key = Authorize::Token.generate_key(2)
    assert_equal "\0" * (Authorize::Token::KEY_SIZE - 2), key[0..13]
  end

  test 'should generate new friendly token' do
    assert_kind_of Authorize::Token, token = Authorize::Token.generate(2)
    assert_equal Authorize::Token::KEY_SIZE, token.key.length
    assert token.mnemonic.size < 9, token.mnemonic
  end

  test 'should convert integer to key' do
    assert_equal "@" * Authorize::Token::KEY_SIZE, Authorize::Token.i_to_key(85404201893882594751592058335816335424)
  end
  
  test 'should convert key to integer' do
    assert_equal 85404201893882594751592058335816335424, Authorize::Token.key_to_i("@" * Authorize::Token::KEY_SIZE)
  end

  test 'should convert between key and integer' do
    100.times do
      i = rand(2**(Authorize::Token::KEY_SIZE*8))
      assert_equal i, Authorize::Token.key_to_i(Authorize::Token.i_to_key(i))
    end
  end

  test 'should convert mnemonic to key' do
    assert_equal "@" * Authorize::Token::KEY_SIZE, Authorize::Token.mnemonic_to_key("garuhehogatozojifudakeduchibipasosasuponozu")
  end

  test 'should convert key to mnemonic' do
    assert_equal "garuhehogatozojifudakeduchibipasosasuponozu", Authorize::Token.key_to_mnemonic("@" * Authorize::Token::KEY_SIZE)    
  end

  test 'should convert between key and mnemonic' do
    100.times do
      bytes = rand(Authorize::Token::KEY_SIZE) + 1
      key = Authorize::Token.generate_key(bytes)
      assert_equal key, Authorize::Token.mnemonic_to_key(Authorize::Token.key_to_mnemonic(key))
    end
  end

  test 'should generate digest from key' do
    key = "@" * Authorize::Token::KEY_SIZE
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0", Authorize::Token.digest(key)
  end
  
  test 'should build token from key' do
    key = "@" * Authorize::Token::KEY_SIZE
    assert token = Authorize::Token._build(key)
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0", token.digest
  end

  test 'should build token from mnemonic' do
    mnemonic = "garuhehogatozojifudakeduchibipasosasuponozu"
    assert token = Authorize::Token.build(mnemonic)
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0", token.digest
  end
end
