module Authorize
  module Base
    
    PREPOSITIONS = %w(of for in on to at by)
    BOOLEANS = %w(not or and true false)
        
    module EvalParser
      # Parses and evaluates an authorization expression and returns <tt>true</tt> or <tt>false</tt>.
      #
      # The authorization expression is defined by the following grammar:
      #         <expr> ::= (<expr>) | not <expr> | <term> or <expr> | <term> and <expr> | <term>
      #         <term> ::= <role> | <role> <preposition> <model> | <role> <preposition> <class>
      #  <preposition> ::= of | for | in | on | to | at | by
      #        <model> ::= /:*\w+/
      #         <role> ::= /\w+/ | /'.*'/
      #
      # Instead of doing recursive descent parsing (not so fun when we support nested parentheses, etc),
      # we let Ruby do the heavy lifting by identifying terms and replacing them with their boolean equivalents
      # and then letting Ruby eval the resulting expression.
      #
      # 1) Replace all <role> <preposition> <model> matches with their boolean truth state.
      # 2) Replace all <role> matches (carefully avoiding grammer elements) with their boolean truth state.
      # 3) Eval the resulting string

      def parse_authorization_expression( str )
        if str =~ /[^A-Za-z0-9_:'\(\)\s]/
          raise AuthorizationExpressionInvalid, "Invalid authorization expression (#{str})"
          return false
        end
        begin
          expr = replace_role_of_model(str)
          expr = replace_role(expr)
          instance_eval(expr)
        rescue CannotObtainModelObject, CannotObtainUserObject => e
          raise e
          false
        rescue => e
          raise AuthorizationExpressionInvalid, "Cannot parse authorization expression (#{str}):#{e.to_s}"
          false
        end
      end

      def replace_role_of_model(str)
        role_regex = '\s*(\'\s*(.+)\s*\'|(\w+))\s+'
        model_regex = '\s+(:*\w+)'
        parse_regex = Regexp.new(role_regex + '(' + PREPOSITIONS.join('|') + ')' + model_regex)
        str.gsub(parse_regex) do |match|
          " #{process_term($2 || $3, $5)} "
        end
      end

      def replace_role(str)
        role_regex = '\s*(\'\s*(.+)\s*\'|([A-Za-z]\w*))\s*'
        parse_regex = Regexp.new(role_regex)
        str.gsub(parse_regex) do |match|
          if BOOLEANS.include?($3)
            " #{match} "
          else
          " #{process_term($2 || $3)} "
          end
        end
      end
      
      # Determine if any of the authorized_identities are authorized as the given role over the given subject.
      # We cache the authorized roles to optimize the common pattern of "role1 of widget or role2 of widget or role3 of widget".
      def process_term(role, model_name = nil)
        subject = model_name.nil? ? nil : get_model(model_name)
        logger.debug("***Checking for authorization of #{authorized_identities.join(', ')} as #{role} over #{subject.to_s}")
        @authorized_roles ||= {}
        @authorized_roles[subject] ||= Authorization.find_effective(subject, authorized_identities).map(&:role)
        @authorized_roles[subject].include?(role)
      end
    end
  end
end