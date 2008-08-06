class User < ActiveRecord::Base
  cattr_accessor :current # Class attribute automatically set after authentication
  
  acts_as_trustee
  
  def identities
    [self.id]
  end
end