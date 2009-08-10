module Authorize
  # Represents an authorization expression, including evaluation options and cached database responses.
  class Expression
    PREPOSITIONS = %w(of for in on to at by)
    BOOLEANS = %w(not or and true false)
  
    attr_reader :expression, :controller, :options

    include Authorize::Parser  # RecursiveDescentParser is another option

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