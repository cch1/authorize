# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   trustee.is_role?                      --> Predicate.  Returns boolean based on trustee having global role
#   trustee.is_role_of? object            --> Predicate.  Returns boolean based on trustee having role of object
#   trustee.is_role_for object            --> Imperative.  Gives user authorization as role for object
#   trustee.is_role                       --> Imperative.  Gives user global role authorization
#   trustee.is_role_of_what               --> Returns array of objects for which trustee is role
#
#   object.has_roles                      --> Returns array of trustees having role over the object
#   object.has_roles?                     --> Predicate.  Returns boolean based having at least one trustee with role
module Authorize
  module Identity

    module TrusteeExtensions
      module InstanceMethods
        REJECT_WHEN_MISSING_OBJECT_OF_PREPOSITION = true

        base = "is_(\\w+)"
        base_not = "is_no[t]?_(\\w+)"
        IMPERATIVE = /^#{base}$/
        IMPERATIVE_WITH_OBJECT = /^#{base}_(#{Authorize::Expression::PREPOSITIONS.join('|')})$/
        INVERSE_IMPERATIVE = /^#{base_not}$/
        INVERSE_IMPERATIVE_WITH_OBJECT = /^#{base_not}_(#{Authorize::Expression::PREPOSITIONS.join('|')})$/
        PREDICATE = /^#{base}\?$/
        PREDICATE_WITH_OBJECT = /^#{base}_(#{Authorize::Expression::PREPOSITIONS.join('|')})\?$/
        OBJECTS = /^#{base}_(#{Authorize::Expression::PREPOSITIONS.join('|')})_what$/

        def method_missing(method, *args)
          object = args.first
          case method.to_s
            when OBJECTS
              subjects_as($1)
            when PREDICATE_WITH_OBJECT
              raise AuthorizationExpressionInvalid if object.nil? && REJECT_WHEN_MISSING_OBJECT_OF_PREPOSITION
              authorized?($1, object)
            when PREDICATE
              authorized?($1)
            when INVERSE_IMPERATIVE_WITH_OBJECT
              raise AuthorizationExpressionInvalid if object.nil? && REJECT_WHEN_MISSING_OBJECT_OF_PREPOSITION
              unauthorize($1, object)
            when INVERSE_IMPERATIVE
              unauthorize($1)
            when IMPERATIVE_WITH_OBJECT
              raise AuthorizationExpressionInvalid if object.nil? && REJECT_WHEN_MISSING_OBJECT_OF_PREPOSITION
              authorize($1, object)
            when IMPERATIVE
              authorize($1)
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
        TRUSTEES_PREDICATE = /^has_(\w+)\?$/
        TRUSTEES = /^has_(\w+)$/

        def method_missing(method_sym, *args)
          method_name = method_sym.to_s
          if method_name =~ TRUSTEES_PREDICATE
            role = $1.singularize
            self.subjections.as(role).any?
          elsif method_name =~ TRUSTEES
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