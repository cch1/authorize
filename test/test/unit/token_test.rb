require 'test_helper'


class TokenTest < ActiveSupport::TestCase
  fixtures :users, :widgets, :authorizations

  test 'should generate random token' do
    tokens = (0..99).map {Token.generate.first}
    assert_equal 100, tokens.uniq.size
  end

  test 'should generate digest from key' do
    key = "@" * 16
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0"[0, Token.size], Token.digest(key)
  end

  test 'should generate new friendly token' do
    100.times do
      bits = rand(256) + 1
      token = ::Token.random(bits)
      syllables = (Math.log(2**bits)/Math.log(70)).ceil
      assert_operator token.mnemonic.size, :<=, syllables * 3, "#{bits} : #{syllables} (#{token.mnemonic})"
    end
  end

  test 'should build token from key' do
    key = "@" * 16
    assert token = ::Token._build(key)
    assert_equal Token.size, token.digest.length
    assert_equal "11e6d3f0fd388ab346a306839ab938aa35256f61a32b0114f5d3ca4b357cb0a0"[0, Token.size], token.digest
  end

  test 'should build token from mnemonic' do
    mnemonic = "garuhehogatozojifudakeduchibipasosasuponozu"
    assert token = ::Token.build(mnemonic)
    assert_equal "69e51555c51d8a12791f2bc697bfafff7ebe1006666dca9d7fcccc13434ce14a"[0, Token.size], token.digest
  end

  test 'should associate' do
    token = ::Token._build(:chris_authorization_token)
    assert_equal 2, token.permissions.size
  end
end