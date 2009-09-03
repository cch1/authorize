# Provides the appearance of dynamically generated methods on the roles database.  Note that none of these methods 
#
# Examples:
#   trustee.is_member?                     --> Returns true if user has any authorization with role "member"
#   trustee.is_member_of? this_workshop    --> Returns true/false. Must have subject object after query.
#   trustee.is_proxy_for this_client       --> Gives user authorization as "proxy" for "client"
#   trustee.is_moderator                   --> Gives user "moderator" authorization (not tied to any class or object)
#   trustee.is_candidate_of_what           --> Returns array of subjects for which this user has authorization as a "candidate"
#
#   subject.has_members                   --> Returns array of trustees as "member" authorized on subject
#   subject.has_members?                  --> Returns true/false
module Authorize
  module Identity
    
    module TrusteeExtensions
      module InstanceMethods
        # TODO: Use a single sophisticated Regexp, like this: /^(is)(_)(not)?(\w+?)(_)(#{Authorize::Expression::PREPOSITIONS.join('|')})?(\?)?$/
        def method_missing(method, *args)
          subject = args.first
          base_regex = "is_(\\w+)"
          fancy_regex = base_regex + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"
          is_either_regex = '^((' + fancy_regex + ')|(' + base_regex + '))'
          base_not_regex = "is_no[t]?_(\\w+)"
          fancy_not_regex = base_not_regex + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"      
          is_not_either_regex = '^((' + fancy_not_regex + ')|(' + base_not_regex + '))'
          case method.to_s
            when Regexp.new(is_either_regex + '_what$')
              role = $3 || $6
              subjects_as(role)
            when Regexp.new(is_not_either_regex + '\?$')
              role = $3 || $6
              not authorized?(role, subject)
            when Regexp.new(is_either_regex + '\?$')
              role = $3 || $6
              authorized?(role, subject)
            when Regexp.new(is_not_either_regex + '$')
              role = $3 || $6
              unauthorize(role, subject)
            when Regexp.new(is_either_regex + '$')
              role = $3 || $6
              authorize(role, subject)
            else
              super
          end
        end
      
        private
        def subjects_as(role)
          authorizations.as(role).map do |a|
            if a.subject_type.nil?
              nil
            elsif a.subject_id.nil?
              a.subject_type.constantize
            else
              a.subject
            end
          end
        end
      end # InstanceMethods Module
    end # TrusteeExtensions Module
    
    module SubjectExtensions
      module InstanceMethods
        def method_missing(method_sym, *args)
          method_name = method_sym.to_s
          if method_name =~ /^has_(\w+)\?$/
            role = $1.singularize
            self.subjections.as(role).any?
          elsif method_name =~ /^has_(\w+)$/
            role = $1.singularize
            self.subjections.as(role).map { |auth| auth.trustee }
          else
            super
          end
        end
      end
    end # SubjectExtensions Module
  end # Identity Module
end # Auth Module