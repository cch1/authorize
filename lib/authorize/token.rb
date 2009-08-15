require 'digest'
require 'rufus/mnemo'

module Authorize
  class Token < String
    SIZE = 32
    SALT = "Replace this value with an application-specific value of your choosing."
    KEY_BITS = 128
    attr_reader :key, :digest
    
    include AuthorizationsTable::TrusteeExtensions
    acts_as_trustee(false)

    # Combine key with salt and hash the result
    def self.digest(key)
      message = SALT + key.to_s
      Digest::SHA256.hexdigest(message)[0..SIZE]
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
      key = self.mnemonic_to_key(mnemonic.to_s)
      _build(key)
    end
    
    def self._build(key)
      digest = self.digest(key)
      self.new(digest, key)
    end

    # Construct a shiny new token using a random key.  The size of the random key, measured in bits, can be specified.
    # Generated tokens, having integer keys, can be represented by a mnemonic device
    def self.generate(bits = KEY_BITS)
      key = ActiveSupport::SecureRandom.random_number(2**bits - 1)
      self._build(key)
    end

    def initialize(digest = nil, key = nil)
      @digest = digest
      @key = key
      super(@digest)
    end

    def mnemonic
      @mnemonic ||= begin
        raise("No key available") unless key
        raise("Non-integer key") unless key.kind_of?(Integer)
        self.class.key_to_mnemonic(key) 
      end
    end

    def permissions
      Authorization.with(self)
    end
  end
end