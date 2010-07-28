require 'test_helper'

class BitmaskTest < ActiveSupport::TestCase
  def setup
    @bitmask = Class.new(Authorize::Bitmask)
    @bitmask.name_values = {:none => 0, :first => 1, :second => 2, :third => 4, :fourth => 8, :first_nibble => 15, :fifth => 16, :sixth => 32, :seventh => 64, :eighth => 128, :all => 255}
  end

  test 'create degenerate' do
    b = @bitmask[]
    assert b.empty?
  end

  test 'create with integer' do
    b = @bitmask.new(4)
    assert_equal Set[:none, :third], b
  end

  test 'create with invalid integer' do
    assert_raises RangeError do
      b = @bitmask.new(256)
    end
  end

  test 'create with enum' do
    b = @bitmask[:first, :third]
    assert_equal Set[:first, :third], b
  end

  test 'create with invalid enum' do
    assert_raises ArgumentError do
      @bitmask[:first, :third, :ninth]
    end
  end

  test 'add bit' do
    b = @bitmask[]
    b << :first_nibble
    assert_equal 15, b.to_i
  end

  test 'add invalid bit' do
    b = @bitmask[]
    assert_raises ArgumentError do
      b.add :first_word
    end
  end

  test 'comparable' do
    b0 = @bitmask[]
    b1 = @bitmask[:first, :second, :third, :fourth]
    b2 = @bitmask[:first_nibble]
    assert_operator b0, :<, b1
    assert_operator b2, :==, b1
  end

  test 'comparable with integers' do
    b0 = @bitmask[:all]
    assert_operator b0, :==, 255
    assert_operator 255, :==, b0
  end

  test 'complete' do
    b = @bitmask[]
    assert_equal Set[:none], b.complete
    b = @bitmask[:first_nibble]
    assert_equal Set[:none, :first, :second, :third, :fourth, :first_nibble], b.complete
    b = @bitmask[:first, :second, :third, :fourth]
    assert_equal Set[:none, :first, :second, :third, :fourth, :first_nibble], b.complete
  end

  test 'fundamental' do
    b = @bitmask[:first_nibble]
    assert_equal Set[:first, :second, :third, :fourth], b.fundamental
  end

  test 'minimal' do
    b = @bitmask[:none, :first, :second, :third, :fourth]
    assert_equal Set[:first_nibble], b.minimal
  end

  test 'stringify' do
    b = @bitmask.new(7)
    assert_match /\w+(\s\|\s\w+){3}/, b.to_s
    assert_match /none.*third/, b.to_s # canonical order
  end

  test 'stringify empty set' do
    b = @bitmask[]
    assert_equal "", b.to_s
  end
end