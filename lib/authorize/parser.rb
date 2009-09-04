module Authorize
  module Parser
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
    def parse(str)
      raise AuthorizationExpressionInvalid, "Invalid authorization expression (#{str})" unless str =~ /[A-Za-z0-9_\(\)\s]*/ 
      begin
        replace_terms(str)
      rescue CannotObtainModelObject, CannotObtainModelClass, CannotObtainTokens => e
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
      re = /(\w+)\s(?:#{Expression::PREPOSITIONS.join('|')})\s(\w+)|\b(?!#{Expression::BOOLEANS.join('|')})(\w+)\b/
      string.gsub(re) do |match|
        params = [$1, $2, $3].compact
         "process_term('#{params.join("','")}')"
      end
    end

    # Determine if any of the authorized_identities are authorized as the given role over the given subject.
    # We cache the authorized roles to optimize the common pattern of "role1 of widget or role2 of widget or role3 of widget".
    def process_term(role, model_name = nil)
      subject = model_name.nil? ? nil : get_model(model_name)
      Authorization.logger.debug("***Checking for authorization of #{get_tokens.to_a.join(', ')} as #{role} over #{(subject || '!Everything!').to_s}")
      @authorized_roles ||= {}
      @authorized_roles[subject] ||= Authorization.find_effective(subject, get_tokens).map(&:role)
      @authorized_roles[subject].include?(role)
    end
  end
end