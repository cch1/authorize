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
      
      # Allow class-level authorization check.
      # permit is used in a before_filter fashion and passes arguments to the before_filter. 
      def permit(authorization_expression, *args)
        filter_keys = [ :only, :except ]
        filter_args, eval_args = {}, {}
        if args.last.is_a? Hash
          filter_args.merge!(args.last.reject {|k,v| not filter_keys.include? k }) 
          eval_args.merge!(args.last.reject {|k,v| filter_keys.include? k }) 
        end
        append_before_filter(filter_args) do |controller|
          controller.permit(authorization_expression, eval_args)
        end      
      end
    end
    
    module ControllerInstanceMethods
      include Authorize::Base::EvalParser  # RecursiveDescentParser is another option
      
      # Permit? turns off redirection by default and takes no blocks
      def permit?(authorization_expression, *args)
        @options = { :allow_guests => false, :callback => false }
        @options.merge!(args.last.is_a?(Hash) ? args.last : {})
        
        has_permission?(authorization_expression)
      end

      # Allow method-level authorization checks.
      # permit (without a trailing question mark) invokes the callback "handle_authorization_failure" by default.
      # Specify :callback => false to turn off callbacks.
      def permit(authorization_expression, *args)
        @options = { :allow_guests => false, :callback => true }
        @options.merge!(args.last.is_a?(Hash) ? args.last : {})
        
        if has_permission?(authorization_expression)
          yield if block_given?
        else 
          handle_authorization_failure if @options[:callback]
        end
      end
            
      private
      
      def has_permission?(authorization_expression)
        parse_authorization_expression(authorization_expression)
      end
      
      def authorized_identities
        u = get_user
        u.respond_to?(:identities) ? u.identities : [u]
      end
      
      # Handle authorization failure within permit.  Override this callback in your ApplicationController
      # for custom behavior.  This method typically returns the value for the around_filter
      def handle_authorization_failure
        raise Authorize::AuthorizationError, 'You are not authorized for the requested operation.'
      end

      # Try to find current user by checking options hash and instance method in that order.
      def get_user
        returning @options[:user] || (methods.include?('current_user') && current_user) || (Object.const_defined?('User') && User.current) do |u|
          raise CannotObtainUserObject unless u || @options[:allow_guests]
        end
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
          if @options[model_symbol]
            @options[model_symbol]
          elsif instance_variables.include?('@' + model_name)
            instance_variable_get('@' + model_name)
          # Note -- while the following code makes autodiscovery more convenient, it's a little too much side effect & security question
          # elsif self.params[:id]
          #  eval_str = model_name.camelize + ".find(#{self.params[:id]})"
          #  eval eval_str
          else
            raise CannotObtainModelObject, "Couldn't find model (#{str}) in hash or as an instance variable"
          end
        end
      end
    end
  end
end