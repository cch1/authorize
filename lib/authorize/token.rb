require 'digest'
require 'rufus/mnemo'

module Authorize
  class Token
    SALT = "Replace this value with an application-specific value of your choosing."
    KEY_SIZE = 16
    attr_reader :key, :digest

    # Normalize the key, combine with salt and hash the result
    def self.digest(key)
      message = SALT + key
      Digest::SHA256.hexdigest(message)
    end

    def self.generate_key(bytes = KEY_SIZE)
      ("\0" * (KEY_SIZE - bytes)) + ActiveSupport::SecureRandom.random_bytes(bytes)
    end

    # Part One: The reversible key<->integer encoding standard
    def self.i_to_key(i)
      i.to_s(16).rjust(KEY_SIZE * 2, '0').to_a.pack("H*") # fixnum -> hexstring (zero padded) -> binary string
    end
    
    # Part Two: The reversible key<->integer encoding standard
    def self.key_to_i(key)
      key.unpack("H*").first.hex # binary string -> hex string -> fixnum
    end
    
    # Part One: The reversible key<->mnemonic encoding standard
    def self.mnemonic_to_key(mnemonic)
      i = Rufus::Mnemo::to_integer(mnemonic)
      self.i_to_key(i)      
    end

    # Part Two: The reversible key<->mnemonic encoding standard
    def self.key_to_mnemonic(key)
      i = self.key_to_i(key) 
      Rufus::Mnemo::from_integer(i)
    end

    # Build a token from a mnemonic string in Rufus::Mnemo format
    def self.build(mnemonic)
      key = self.mnemonic_to_key(mnemonic)
      _build(key)
    end
    
    def self._build(key)
      digest = self.digest(key)
      self.new(digest, key)
    end

    # Construct a shiny new token using a random key.  The size of the random key, measured in bytes, can be specified.
    def self.generate(bytes = KEY_SIZE)
      self.new.tap {|t| t.generate!(bytes)}
    end

    def initialize(digest = nil, key = nil)
      @digest = digest
      @key = key
    end

    def generate!(bytes = KEY_SIZE)
      raise "Already generated." if digest
      @key = self.class.generate_key(bytes)
      @digest = self.class.digest(key)
    end

    def mnemonic
      @mnemonic ||= begin
        raise("No key available") unless key
        self.class.key_to_mnemonic(key) 
      end
    end

    def to_s
      digest
    end
    alias to_str to_s
  end
end