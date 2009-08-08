module Authorize #:nodoc:

  # Base error class for Authorization module
  class AuthorizationError < StandardError
  end
  
  # Raised when the authorization expression is invalid (cannot be parsed)
  class AuthorizationExpressionInvalid < AuthorizationError
  end
  
  # Raised when we can't find the current user
  class CannotObtainTokens < AuthorizationError
  end
  
  # Raised when an authorization expression contains a model class that doesn't exist
  class CannotObtainModelClass < AuthorizationError
  end
  
  # Raised when an authorization expression contains a model reference that doesn't exist
  class CannotObtainModelObject < AuthorizationError
  end
  
  # Raised when the obtained trustee object doesn't implement #has_role?
  class TrusteeDoesntImplementRoles < AuthorizationError
  end
  
  # Raised when the obtained model doesn't implement #accepts_role?
  class ModelDoesntImplementRoles < AuthorizationError
  end
end