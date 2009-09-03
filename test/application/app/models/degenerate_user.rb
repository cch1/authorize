class ::DegenerateUser
  include Authorize::AuthorizationsTable::TrusteeExtensions
  acts_as_trustee(false)

  def authorization_token
    object_id
  end

  def permissions # must return a named scope or an association or a class
    Authorization.with(authorization_token)
  end

  # Should return the trustee possessing the given authorization token.
  def find_by_authorization_token(token)
    ObjectSpace._id2ref(token)
  end
end  