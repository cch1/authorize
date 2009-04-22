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
      #        <model> ::= /\w+/
      #         <role> ::= /\w+/
      #
      # We let Ruby do the heavy lifting by identifying terms and replacing them with their boolean equivalents
      # and then letting Ruby eval the resulting boolean expression.
      def parse_authorization_expression(str)
        if str =~ /[^A-Za-z0-9_\(\)\s]/
          raise AuthorizationExpressionInvalid, "Invalid authorization expression (#{str})"
          return false
        end
        begin
          expr = replace_terms(str)
          instance_eval(expr)
        rescue CannotObtainModelObject, CannotObtainUserObject => e
          raise e
        rescue => e
          raise AuthorizationExpressionInvalid, "Cannot parse authorization expression:#{e.to_s}"
        end
      end

      # This method replaces term strings with their processed (boolean) equivalent.  Term strings are either
      # <role> <preposition> <model-or-class> or simply <role>.  The regular expression used to find term strings
      # looks for either pairs of words separated by prepositions or, using negative lookahead, words that are not
      # part of the Ruby boolean language.
      def replace_terms(string)
        re = /(\w+)\s(?:#{PREPOSITIONS.join('|')})\s(\w+)|\b(?!#{BOOLEANS.join('|')})(\w+)\b/
        string.gsub(re) do |match|
          params = [$1, $2, $3].compact
           "process_term('#{params.join("','")}')"
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