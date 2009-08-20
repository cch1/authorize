module Authorize
  module Base
    def self.included(recipient)
      if recipient.respond_to?(:rescue_responses)
        recipient.rescue_responses['Authorize::AuthorizationError'] = :forbidden
      end
      recipient.extend(ControllerClassMethods)
      recipient.class_eval do
        include ControllerInstanceMethods
      end
    end
    
    module ControllerClassMethods      
      # Allow action-level authorization check with an appended before_filter.
      def permit(authorization_expression, options = {})
        auth_options = options.slice!(:only, :except)
        append_before_filter(options) do |controller|
          controller.permit(authorization_expression, options)
        end      
      end
    end
    
    module ControllerInstanceMethods
      # Simple predicate for authorization.
      def permit?(authorization_expression, options = {})
        Expression.new(authorization_expression, self, options).eval
      end

      # Allow method-level authorization checks.
      # permit (without a trailing question mark) invokes the callback "handle_authorization_failure" by default.
      # Specify :callback => false to turn off callbacks.
      def permit(authorization_expression, options = {})
        options.reverse_merge!(:callback => true)
        callback = options.delete(:callback)
        if permit?(authorization_expression, options)
          yield if block_given?
        else 
          handle_authorization_failure if callback
        end
      end
            
      private
      # Handle authorization failure within permit.  Override this callback in your ApplicationController
      # for custom behavior.  This method typically returns the value for the around_filter
      def handle_authorization_failure
        raise Authorize::AuthorizationError, 'You are not authorized for the requested operation.'
      end
    end
  end
end