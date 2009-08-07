class User < ActiveRecord::Base
  cattr_accessor :current # Class attribute automatically set after authentication
  
  acts_as_trustee
  
  def authorization_tokens
    [self.authorization_token]
  end
end