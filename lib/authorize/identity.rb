# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   trustee.is_role?                       --> Predicate.  Returns boolean based on trustee having global role
#   trustee.is_role_of? subject            --> Predicate.  Returns boolean based on trustee having role of subject
#   trustee.is_role_for subject            --> Imperative.  Gives user authorization as role for subject
#   trustee.is_role                        --> Imperative.  Gives user global role authorization
#   trustee.is_role_of_what                --> Returns array of subjects for which trustee is role
#
#   subject.has_roles                      --> Returns array of trustees having role over the subject
#   subject.has_roles?                     --> Predicate.  Returns boolean based having at least one trustee with role
module Authorize
  module Identity

    module TrusteeExtensions
      module InstanceMethods
        base = "is_(\\w+)"
        fancy = base + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"
        is_either = '^((' + fancy + ')|(' + base + '))'
        base_not = "is_no[t]?_(\\w+)"
        fancy_not = base_not + "_(#{Authorize::Expression::PREPOSITIONS.join('|')})"
        is_not_either = '^((' + fancy_not + ')|(' + base_not + '))'
        # TODO: Use a single sophisticated Regexp, like this: /^(is)(_)(not)?(\w+?)(_)(#{Authorize::Expression::PREPOSITIONS.join('|')})?(\?)?$/
        EITHER_SUBJECTS = /#{is_either}_what$/
        NEITHER_PREDICATE = /#{is_not_either}\?$/
        EITHER_PREDICATE = /#{is_either}\?$/
        NOT_EITHER = /#{is_not_either}$/
        EITHER = /#{is_either}$/

        def method_missing(method, *args)
          subject = args.first
          case method.to_s
            when EITHER_SUBJECTS
              role = $3 || $6
              subjects_as(role)
            when NEITHER_PREDICATE
              role = $3 || $6
              not authorized?(role, subject)
            when EITHER_PREDICATE
              role = $3 || $6
              authorized?(role, subject)
            when NOT_EITHER
              role = $3 || $6
              unauthorize(role, subject)
            when EITHER
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