module Authorize
  module Base
  
    # Modify these constants in your environment.rb to tailor the plugin to your authentication system
    if not Object.constants.include? "DEFAULT_REDIRECTION_HASH"
      DEFAULT_REDIRECTION_HASH = { :controller => 'sessions', :action => 'new' }
    end    
    if not Object.constants.include? "STORE_LOCATION_METHOD"
      STORE_LOCATION_METHOD = :store_location
    end    

    def self.included( recipient )
      if recipient.respond_to?(:rescue_responses)
        recipient.rescue_responses['Authorize::AuthorizationError'] = :forbidden
      end
      recipient.extend( ControllerClassMethods )
      recipient.class_eval do
        include ControllerInstanceMethods
      end
    end
    
    module ControllerClassMethods
      
      # Allow class-level authorization check.
      # permit is used in a before_filter fashion and passes arguments to the before_filter. 
      def permit( authorization_expression, *args )
        filter_keys = [ :only, :except ]
        filter_args, eval_args = {}, {}
        if args.last.is_a? Hash
          filter_args.merge!( args.last.reject {|k,v| not filter_keys.include? k } ) 
          eval_args.merge!( args.last.reject {|k,v| filter_keys.include? k } ) 
        end
        prepend_before_filter( filter_args ) do |controller|
          controller.permit( authorization_expression, eval_args )
        end      
      end
    end
    
    module ControllerInstanceMethods
      include Authorize::Base::EvalParser  # RecursiveDescentParser is another option
      
      # Permit? turns off redirection by default and takes no blocks
      def permit?( authorization_expression, *args )
        @options = { :allow_guests => false, :callback => false }
        @options.merge!( args.last.is_a?( Hash ) ? args.last : {} )
        
        has_permission?( authorization_expression )
      end

      # Allow method-level authorization checks.
      # permit (without a trailing question mark) invokes the callback "handle_authorization_failure" by default.
      # Specify :callback => false to turn off callbacks.
      def permit(authorization_expression, *args)
        @options = { :allow_guests => false, :callback => true }
        @options.merge!( args.last.is_a?( Hash ) ? args.last : {} )
        
        if has_permission?(authorization_expression)
          yield if block_given?
        else 
          handle_authorization_failure if @options[:callback]
        end
      end
            
      private
      
      def has_permission?( authorization_expression )
        @current_user = get_user
        if not @options[:allow_guests]
          if @current_user.nil?  # We aren't logged in, or an exception has already been raised
            return false
          elsif not @current_user.respond_to? :id
            raise( UserDoesntImplementID, "User doesn't implement #id")
            return false
          elsif not @current_user.respond_to? :authorized?
            raise( UserDoesntImplementRoles, "User doesn't implement #authorized?" )
            return false
          end
        end
        parse_authorization_expression( authorization_expression )
      end
      
      # Handle authorization failure within permit.  Override this callback in your ApplicationController
      # for custom behavior.  This method typically returns the value for the around_filter
      def handle_authorization_failure
        raise Authorize::AuthorizationError, 'You are not authorized for the requested operation.'
      end

      # Try to find current user by checking options hash and instance method in that order.
      def get_user
        if @options[:user]
          @options[:user]
        elsif @options[:get_user_method]
          send( @options[:get_user_method] )
        elsif methods.include? "current_user"
          current_user
        elsif not @options[:allow_guests]
          raise( CannotObtainUserObject, "Couldn't find #current_user or @user, and nothing appropriate found in hash" )
        end
      end
      
      # Try to find a model to query for permissions
      def get_model( str )
        if str =~ /\s*([A-Z]+\w*)\s*/
          # Handle model class
          begin
            Module.const_get( str )
          rescue
            raise CannotObtainModelClass, "Couldn't find model class: #{str}"
          end
        elsif str =~ /\s*:*(\w+)\s*/
          # Handle model instances
          model_name = $1
          model_symbol = model_name.to_sym
          if @options[model_symbol]
            @options[model_symbol]
          elsif instance_variables.include?( '@'+model_name )
            instance_variable_get( '@'+model_name )
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