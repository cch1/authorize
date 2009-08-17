require File.dirname(__FILE__) + '/identity'

module Authorize
  module AuthorizationsTable

    module TrusteeExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_trustee(key = :authorization_token)
          if key
            # We would like to use :dependent => :delete_all (no sense instantiating the Authorization instance), but it fails to delete the
            # associated authorizations.  Seems like a bug in respecting the "primary_key" option.
            # TODO: revert this to :delete_all when the bug is resolved.
            has_many :permissions, :primary_key => key.to_s, :foreign_key => 'token', :class_name => 'Authorization', :dependent => :destroy
            class_eval do
              alias :authorizations :permissions 
            end
          end
          include Authorize::AuthorizationsTable::TrusteeExtensions::InstanceMethods
          include Authorize::Identity::TrusteeExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end

      module InstanceMethods
        def authorized?(role, subject = nil)
          !!permissions.as(role).for(subject).any?
        end

        def authorize(role, subject = nil, parent = nil)
          unless auth = permissions.as(role).for(subject).first
            attrs = respond_to?(:parent) ? {:parent => parent} : {} # Support tree-structured authorizations.
            auth = permissions.as(role).for(subject).create(attrs)
            Authorization.logger.debug "#{self} authorized as #{role} over #{subject} (derived from #{parent})"
          end
          auth
        end

        def unauthorize(role, subject = nil)
          permissions.as(role).for(subject).delete_all
        end
      end 
    end
        
    module SubjectExtensions
      ConditionClause = "EXISTS (SELECT 1 FROM authorizations a WHERE (a.subject_type IS NULL OR (a.subject_type = ? AND (a.subject_id = ?.? OR a.subject_id IS NULL))) AND a.token IN (?))"
      # The above statement does not optimize well on MySQL 5.0, probably due to the presence of NULLs and ORs.  Forcing the use of an appropriate index solves the problem. 
      # Another (temporary) solution was to delete the other indices that caused MySQL to poorly optimize queries with this condition.  When other indices are required, consider the following query: 
#      ConditionClause = "EXISTS (SELECT true FROM authorizations a USE INDEX (subject_trustee_role) WHERE (a.subject_type IS NULL OR (a.subject_type = '%s' AND (a.subject_id = %s.%s OR a.subject_id IS NULL))) AND a.trustee_id IN (%s) %s)"

      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_subject
          has_many :subjections, :as => :subject, :class_name => 'Authorization', :dependent => :delete_all
          include Authorize::AuthorizationsTable::SubjectExtensions::InstanceMethods
          include Authorize::Identity::SubjectExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
          extend Authorize::AuthorizationsTable::SubjectExtensions::SingletonMethods
          named_scope :authorized, lambda {|tokens, roles|
            tokens = [tokens].flatten
            conditions = [ConditionClause, self.to_s, self.table_name, self.primary_key, tokens]
            if roles
              conditions[0] = ConditionClause.dup.insert(-2, " AND a.role IN (?)")
              conditions << [roles].flatten.map(&:to_s)
            end
            {:conditions => conditions}
          }
        end
      end

      module SingletonMethods
        def subjected?(role, trustee)
          trustee.authorized?(role, self)
        end

        def subject(role, trustee, parent = nil)
          trustee.authorize(role, self, parent)
        end

        def unsubject(role, trustee)
          trustee.unauthorize(role, self)
        end

        def subjections
          Authorization.for(self)
        end
      end     

      module InstanceMethods
        def subjected?(role, trustee)
          trustee.authorized?(role, self)
        end

        def subject(role, trustee, parent = nil)
          trustee.authorize(role, self, parent)
        end

        def unsubject(role, trustee)
          trustee.unauthorize(role, self)
        end
      end    
    end
  end
end