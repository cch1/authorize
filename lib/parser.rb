module Authorize
  module Base
    
    VALID_PREPOSITIONS = ['of', 'for', 'in', 'on', 'to', 'at', 'by']
    BOOLEAN_OPS = ['not', 'or', 'and']
    VALID_PREPOSITIONS_PATTERN = VALID_PREPOSITIONS.join('|')
        
    module EvalParser
      # Parses and evaluates an authorization expression and returns <tt>true</tt> or <tt>false</tt>.
      #
      # The authorization expression is defined by the following grammar:
      #         <expr> ::= (<expr>) | not <expr> | <term> or <expr> | <term> and <expr> | <term>
      #         <term> ::= <role> | <role> <preposition> <model>
      #  <preposition> ::= of | for | in | on | to | at | by
      #        <model> ::= /:*\w+/
      #         <role> ::= /\w+/ | /'.*'/
      #
      # Instead of doing recursive descent parsing (not so fun when we support nested parentheses, etc),
      # we let Ruby do the work for us by inserting the appropriate permission calls and using eval.
      # This would not be a good idea if you were getting authorization expressions from the outside,
      # so in that case (e.g. somehow letting users literally type in permission expressions) you'd
      # be better off using the recursive descent parser in Module RecursiveDescentParser.
      #
      # We search for parts of our authorization evaluation that match <role> or <role> <preposition> <model>
      # and we ignore anything terminal in our grammar.
      #
      # 1) Replace all <role> <preposition> <model> matches.
      # 2) Replace all <role> matches that aren't one of our other terminals ('not', 'or', 'and', or preposition)
      # 3) Eval
      
      def parse_authorization_expression( str )
        if str =~ /[^A-Za-z0-9_:'\(\)\s]/
          raise AuthorizationExpressionInvalid, "Invalid authorization expression (#{str})"
          return false
        end
        @replacements = []
        expr = replace_temporarily_role_of_model( str )
        expr = replace_role( expr )
        expr = replace_role_of_model( expr )
        begin
          instance_eval( expr )
        rescue CannotObtainModelObject, CannotObtainUserObject => e
          raise e
          false
        rescue => e
          raise AuthorizationExpressionInvalid, "Cannot parse authorization expression (#{str}):#{e.to_s}"
          false
        end
      end
      
      def replace_temporarily_role_of_model( str )
        role_regex = '\s*(\'\s*(.+)\s*\'|(\w+))\s+'
        model_regex = '\s+(:*\w+)'
        parse_regex = Regexp.new(role_regex + '(' + VALID_PREPOSITIONS.join('|') + ')' + model_regex)
        str.gsub(parse_regex) do |match|
          @replacements.push " process_role_of_model('#{$2 || $3}', '#{$5}') "
          " <#{@replacements.length-1}> "
        end
      end
      
      def replace_role( str )
        role_regex = '\s*(\'\s*(.+)\s*\'|([A-Za-z]\w*))\s*'
        parse_regex = Regexp.new(role_regex)
        str.gsub(parse_regex) do |match|
          if BOOLEAN_OPS.include?($3)
            " #{match} "
          else
            " process_role('#{$2 || $3}') "
          end
        end
      end
      
      def replace_role_of_model( str )
        str.gsub(/<(\d+)>/) do |match|
          @replacements[$1.to_i]
        end
      end
      
      def process_role_of_model(role, model_name)
        model = get_model(model_name)
        logger.debug("***Checking for authorization of #{authorized_identities.join(', ')} as #{role} over #{model.to_s}")
        @authorized_roles ||= {}
        @authorized_roles[model] ||= Authorization.find_effective(model, authorized_identities).map(&:role)
        @authorized_roles[model].include?(role)
      end
      
      def process_role(role)
        logger.debug("***Checking for authorization of #{authorized_identities.join(', ')} as global #{role}")
        generic_roles = Authorization.generic_authorizations(authorized_identities).map(&:role)
        generic_roles.include?(role)
      end
    end
    
    # Parses and evaluates an authorization expression and returns <tt>true</tt> or <tt>false</tt>.
    # This recursive descent parses uses two instance variables:
    #  @stack --> a stack with the top holding the boolean expression resulting from the parsing
    #
    # The authorization expression is defined by the following grammar:
    #         <expr> ::= (<expr>) | not <expr> | <term> or <expr> | <term> and <expr> | <term>
    #         <term> ::= <role> | <role> <preposition> <model>
    #  <preposition> ::= of | for | in | on | to | at | by
    #        <model> ::= /:*\w+/
    #         <role> ::= /\w+/ | /'.*'/
    #
    # There are really two values we must track:
    # (1) whether the expression is valid according to the grammar
    # (2) the evaluated results --> true/false on the permission queries
    # The first is embedded in the control logic because we want short-circuiting. If an expression
    # has been parsed and the permission is false, we don't want to try different ways of parsing.
    # Note that this implementation of a recursive descent parser is meant to be simple
    # and doesn't allow arbitrary nesting of parentheses. It supports up to 5 levels of nesting.
  end
end