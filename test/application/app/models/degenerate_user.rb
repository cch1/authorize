class ::DegenerateUser
  include Authorize::AuthorizationsTable, Authorize::AuthorizationsTable::TrusteeExtensions
  acts_as_trustee(false)

  def authorization_token
    object_id
  end

  def authorizations # must return a named scope or an association or a class
    Authorization.scoped_by_token(authorization_token)
  end
end  
