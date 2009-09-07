require 'singleton'

class Public
  include Authorize::AuthorizationsTable::TrusteeExtensions
  include Singleton
  TOKEN = 'a' * Authorization.columns_hash['token'].limit

  acts_as_trustee(false)

  def authorization_token
    TOKEN
  end
  
  def permissions
    Authorization.with(TOKEN)
  end
  
  def to_s
    "Public"
  end
end