require 'rufus/mnemo'
require 'digest'

class Token
  cattr_accessor :size, :salt, :key_bits
  self.size = 64
  self.salt = "Replace this value with an application-specific value of your choosing."
  self.key_bits = 256

  include Authorize::AuthorizationsTable::TrusteeExtensions
  acts_as_trustee(false)

  # Generate a shiny new random integer key and token pair.  The size of the key space, measured in bits, can be specified.
  # Generated tokens, having integer keys, can be represented by a mnemonic device and subsequently reconstructed.
  def self.generate(bits = key_bits)
    key = ActiveSupport::SecureRandom.random_number(2**bits - 1)
    return digest(key), key
  end

  # Combine key with salt and hash the result
  def self.digest(key)
    message = salt + key.to_s
    Digest::SHA256.hexdigest(message)[0, size]
  end

  # Part One: The reversible key<->mnemonic encoding standard
  def self.mnemonic_to_key(mnemonic)
    Rufus::Mnemo::to_integer(mnemonic)
  end

  # Part Two: The reversible key<->mnemonic encoding standard
  def self.key_to_mnemonic(key)
    Rufus::Mnemo::from_integer(key.to_i)
  end

  # Build a token from a mnemonic string in Rufus::Mnemo format
  def self.build(mnemonic)
    key = mnemonic_to_key(mnemonic.to_s)
    _build(key)
  end
  
  def self._build(key)
    digest = digest(key)
    self.new(digest, key)
  end
  
  def self.random(bits = size)
    new(*generate(bits))
  end

  attr_reader :key, :digest
  def initialize(digest = nil, key = nil)
    @digest = digest
    @key = key
#      super(@digest)
  end

  def mnemonic
    @mnemonic ||= begin
      raise("No key available") unless key
      raise("Non-integer key") unless key.kind_of?(Integer)
      self.class.key_to_mnemonic(key) 
    end
  end

  def permissions
    Authorization.with(self.to_s)
  end
  
  def to_s
    digest
  end
  
  def to_str
    digest
  end
end
