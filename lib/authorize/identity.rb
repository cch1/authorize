# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   user.is_member?                     --> Returns true if user has any authorization with role "member"
#   user.is_member_of? this_workshop    --> Returns true/false. Must have subject object after query.
#   user.is_eligible_for [this_award]   --> Gives user as "eligible" authorization for "this_award"
#   user.is_moderator                   --> Gives user "moderator" authorization (not tied to any class or object)
#   user.is_candidate_of_what           --> Returns array of objects for which this user a "candidate" has authorization
#
#   model.has_members                   --> Returns array of users as "member" authorized on that model
#   model.has_members?                  --> Returns true/false
#
module Authorize
  module Identity
    
    module TrusteeExtensions
      module InstanceMethods

        def method_missing( method_sym, *args )
          method_name = method_sym.to_s
          subject = args.empty? ? nil : args[0]
        
          base_regex = "is_(\\w+)"
          fancy_regex = base_regex + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"
          is_either_regex = '^((' + fancy_regex + ')|(' + base_regex + '))'
          base_not_regex = "is_no[t]?_(\\w+)"
          fancy_not_regex = base_not_regex + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"      
          is_not_either_regex = '^((' + fancy_not_regex + ')|(' + base_not_regex + '))'
        
          if method_name =~ Regexp.new(is_either_regex + '_what$')
            role = $3 || $6
            has_role_for_objects(role)
          elsif method_name =~ Regexp.new(is_not_either_regex + '\?$')
            role = $3 || $6
            not authorized?(role, subject)
          elsif method_name =~ Regexp.new(is_either_regex + '\?$')
            role = $3 || $6
            authorized?(role, subject)
          elsif method_name =~ Regexp.new(is_not_either_regex + '$')
            role = $3 || $6
            unauthorize(role, subject)
          elsif method_name =~ Regexp.new(is_either_regex + '$')
            role = $3 || $6
            authorize(role, subject)
          else
            super
          end
        end
      
        private
      
#        def is_role?(role, subject)
#          self.authorized?(role, subject)
#        end
#      
#        def is_no_role(role, subject)
#          self.unauthorize role, subject
#        end
#      
#        def is_role(role, subject)
#          self.authorize role, subject
#        end
      
        def has_role_for_objects(role)
          roles = self.authorizations.find_all_by_role( role )
          roles.collect do |role|
            if role.subject_type.nil?
              nil
            elsif role.subject_id.nil?
              Module.const_get( role.subject_type )   # Returns class
            else
              role.subject
            end
          end
        end
      end # InstanceMethods Module
    end # TrusteeExtensions Module
    
    module SubjectExtensions
      module InstanceMethods

        def method_missing( method_sym, *args )
          method_name = method_sym.to_s
          if method_name =~ /^has_(\w+)\?$/
            role = $1.singularize
            self.subjections.find_all_by_role(role).any? { |auth| auth.trustee }
          elsif method_name =~ /^has_(\w+)$/
            role = $1.singularize
            users = self.subjections.find_all_by_role(role).collect { |auth| auth.trustee }
          else
            super
          end
        end
        
      end
    end # ModelExtensions Module

  end # Identity Module
end # Auth Module