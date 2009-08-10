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
        append_before_filter(options.slice!(:only, :except)) do |controller|
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

    # Represents an authorization expression, including evaluation options and cached database responses.
    class Expression
      attr_reader :expression, :controller, :options

      include Authorize::Base::EvalParser  # RecursiveDescentParser is another option

      # Instances depend on the controller for resolving subject references and available tokens. 
      def initialize(expression, controller, options = {})
        @expression = expression
        @controller = controller
        @options = options
      end

      def eval
        instance_eval(parse(expression))
      end

      # Try to find a model to query for permissions
      def get_model(str)
        if str =~ /\s*([A-Z]+\w*)\s*/
          # Handle model class
          begin
            Module.const_get(str)
          rescue
            raise CannotObtainModelClass, "Couldn't find model class: #{str}"
          end
        elsif str =~ /\s*:*(\w+)\s*/
          # Handle model instances
          model_name = $1
          model_symbol = model_name.to_sym
          if options.has_key?(model_symbol)
            options[model_symbol]
          elsif controller.instance_variables.include?('@' + model_name)
            controller.instance_variable_get('@' + model_name)
          else
            raise CannotObtainModelObject, "Couldn't find model (#{str}) in hash or as an instance variable"
          end
        end
      end

      # Get authorization tokens appropriate for this request as accumulated in the #authorization_tokens array.
      def get_tokens
        begin
          ([options[:token]] + [controller.authorization_tokens]).flatten.uniq.compact
        rescue => e
          raise CannotObtainTokens, "Cannot determine authorization tokens: #{e}"
        end
      end      

      def to_s
        expression
      end
    end
  end
end