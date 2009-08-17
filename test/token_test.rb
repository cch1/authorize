require File.expand_path(File.dirname(__FILE__) + "/application/test/test_helper.rb")

class TokenTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations
  
  test 'should generate new friendly token' do
    100.times do
      bits = rand(256) + 1
      token = Authorize::Token.generate(bits)
      syllables = (Math.log(2**bits)/Math.log(70)).ceil
      assert token.mnemonic.size < syllables * 3, "#{bits} : #{syllables} (#{token.mnemonic})"
    end
  end

  test 'should generate digest from key' do
    key = "@" * 16
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0"[0, Authorize::Token::SIZE], Authorize::Token.digest(key)
  end
  
  test 'should build token from key' do
    key = "@" * 16
    assert token = Authorize::Token._build(key)
    assert_equal Authorize::Token::SIZE, token.digest.length
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0"[0, Authorize::Token::SIZE], token.digest
  end

  test 'should build token from mnemonic' do
    mnemonic = "garuhehogatozojifudakeduchibipasosasuponozu"
    assert token = Authorize::Token.build(mnemonic)
    assert_equal "69e51555c51d8a12791f2bc697bfafff7ebe1006666dca9d7fcccc13434ce14a"[0, Authorize::Token::SIZE], token.digest
  end
  
  test 'should associate' do
    token = Authorize::Token._build(:chris_authorization_token)
    assert_equal 2, token.permissions.size
  end
end
