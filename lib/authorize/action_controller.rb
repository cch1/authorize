module Authorize
  module ActionController
    def self.included(recipient)
      if recipient.respond_to?(:rescue_responses)
        recipient.rescue_responses['Authorize::AuthorizationError'] = :forbidden
      end
      recipient.extend(ClassMethods)
      recipient.class_eval do
        include InstanceMethods
        helper_method :permit?
        helper_method :permit
        helper_method :handle_authorization_failure
      end
    end

    module ClassMethods
      # Allow action-level authorization check with an appended before_filter.
      def permit(authorization_expression, options = {})
        auth_options = options.slice!(:only, :except)
        append_before_filter(options) do |controller|
          controller.permit(authorization_expression, auth_options)
        end
      end
    end

    module InstanceMethods
      # Simple predicate for authorization.
      def permit?(authorization_hash, options = {})
        authorization_hash.any? do |(modes, resource)|
          request_mask = Authorize::Permission::Mask[modes]
          roles = options[:roles] || self.roles
          Authorize::Permission.to_do(request_mask).over(resource).as(roles).any?.tap do |authorized|
            Rails.logger.debug("Authorization check: #{authorized ? '✔' : '✖'} #{request_mask}")
          end
        end
      end

      # Allow method-level authorization checks.
      # permit (without a trailing question mark) invokes the callback "handle_authorization_failure" by default.
      # Specify :callback => false to turn off callbacks.
      def permit(authorization_hash, options = {})
        options = {:callback => :handle_authorization_failure}.merge(options)
        callback = options.delete(:callback)
        if permit?(authorization_hash, options)
          yield if block_given?
        else
          __send__(callback) if callback
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