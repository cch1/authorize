require File.dirname(__FILE__) + '/identity'

module Authorize
  module AuthorizationsTable
  
    module TrusteeExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def acts_as_trustee
          has_many :authorizations, :as => :trustee, :dependent => :delete_all
          has_many :permissions, :as => :trustee, :class_name => 'Authorization', :dependent => :delete_all
          include Authorize::AuthorizationsTable::TrusteeExtensions::InstanceMethods
          include Authorize::Identity::TrusteeExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end
      
      module InstanceMethods
        def authorized?(role, subject = nil)
          get_auth_for_trustee(role, subject) ? true : false
        end
        
        def authorize(role, subject = nil, parent = nil)
          auth = get_auth_for_trustee(role, subject)
          if auth.nil?
            logger.debug "#{self} authorized as #{role} over #{subject} (derived from #{parent})"
            attrs = {:role => role}
            if subject.is_a? Class
              attrs.merge!(:subject_type => subject.to_s)
            elsif subject
              attrs.merge!(:subject => subject)
            end
            attrs.merge!(:parent => parent) if respond_to?(:parent) # Support tree-structured authorizations.
            auth = self.authorizations.create(attrs)
          end
          auth
        end
        
        def unauthorize(role, subject = nil)
          auth = get_auth_for_trustee(role, subject)
          if auth
            self.authorizations.delete(auth)
          end
        end

        private
        
        def get_auth_for_trustee(role, subject)
          if subject.is_a? Class
            subject_type = subject.to_s
            subject_id = nil
          elsif subject
            subject_type = subject.class.to_s
            subject_id = subject.id
          else
            subject_type = nil
            subject_id = nil
          end
          self.authorizations.find(:first, :conditions => {:role => role, :subject_type => subject_type, :subject_id => subject_id})
        end        
      end 
    end
        
    module ModelExtensions
      ConditionClause = "EXISTS (SELECT 1 FROM authorizations a WHERE (a.subject_type IS NULL OR (a.subject_type = ? AND (a.subject_id = ?.? OR a.subject_id IS NULL))) AND a.trustee_id IN (?))"
      # The above statement does not optimize well on MySQL 5.0, probably due to the presence of NULLs and ORs.  Forcing the use of an appropriate index solves the problem. 
      # Another (temporary) solution was to delete the other indices that caused MySQL to poorly optimize queries with this condition.  When other indices are required, consider the following query: 
#      ConditionClause = "EXISTS (SELECT true FROM authorizations a USE INDEX (subject_trustee_role) WHERE (a.subject_type IS NULL OR (a.subject_type = '%s' AND (a.subject_id = %s.%s OR a.subject_id IS NULL))) AND a.trustee_id IN (%s) %s)"

      def self.included(recipient)
        recipient.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_subject
          has_many :subjections, :as => :subject, :class_name => 'Authorization', :dependent => :delete_all
          # Handy fluff association -but of limited value.
#          Authorization.belongs_to 'subjected_' + self.to_s.underscore, :foreign_key => "subject_id"
          include Authorize::AuthorizationsTable::ModelExtensions::InstanceMethods
          include Authorize::Identity::ModelExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
          extend Authorize::AuthorizationsTable::ModelExtensions::SingletonMethods
        end
      end

      module SingletonMethods
        def subjected?(role, trustee)
          get_auth_for_subject(role, trustee) ? true : false
        end
        
        def subject(role, trustee, parent = nil)
          trustee.authorize role, self, parent
        end
        
        def unsubject(role, trustee)
          trustee.unauthorize role, self
        end
        
        def subjections(trustee = nil)
          conditions = {:subject_type => self.to_s, :subject_id => nil}
          conditions[:trustee_id] = trustee if trustee # Isn't trustee mandatory?
          Authorization.find(:all, :conditions => conditions)
        end
        
        # This method encapsulates an ugly-but-useful coupling between models and the User.current class method.
        # Override it to specify which trustees should be used by default to perform an authorized_{find, count}.
        def default_identities 
          raise CannotObtainUserObject unless User && User.current 
          User.current.respond_to?(:identities) ? User.current.identities : [User.current]
        end

        # Count the number of persisted model instances for which the trustee(s) are authorized.  The interface
        # to AR::Base.count is extended with the following options:
        #   * trustees  an array of trustees whose authorizations are to be searched (default comes from default_identities class method)
        #   * roles     an array of roles to be searched
        def authorized_count(*args)
          column_name = :all
          if args.size > 0
            if args[0].is_a?(Hash)
              options = args[0]
            else
              column_name, options = args
            end
            options = options.dup
          end
          options ||= {}
          trustees = options.delete(:trustees) || default_identities
          with_scope(:find => authorized_conditions(trustees, options.delete(:roles))) do
            count(column_name, options)
          end
        end
          
        # Find persisted model instances for which the trustee(s) are authorized.  The interface to AR::Base.find
        # is extended with the following options:
        #   * trustees  an array of trustees whose authorizations are to be searched (default comes from default_identities class method)
        #   * roles     an array of roles to be searched
        def authorized_find(*args)
          options = args.last.is_a?(Hash) ? args.pop.dup : {}
          trustees = options.delete(:trustees) || default_identities
          with_scope(:find => authorized_conditions(trustees, options.delete(:roles))) do
            find(args.first, options)
          end
        end
        
        private          
        def get_auth_for_subject(role, trustee)
          trustee.authorizations.find(:first, :conditions => {:role => role, :subject_type => self.to_s, :subject_id => nil})
        end

        # Build a SQL WHERE clause element that restricts model queries to return only authorized instances.  Eligible
        # authorizations can be restricted by role (default: all roles) and by trustee (default: default_identities). 
        # TODO: Optimize query to use '=' instead of the IN () construct when only a single role or trustee is provided.
        def authorized_conditions(trustees = default_identities, roles = nil)
          conditions = [ConditionClause, self.to_s, self.table_name, self.primary_key, trustees]
          if roles
            conditions[0] = ConditionClause.dup.insert(-2, " AND a.role IN (?)")
            conditions << roles
          end
          {:conditions => conditions}
        end
      end     

      module InstanceMethods
        def subjected?(role, trustee)
          get_auth_for_subject(role, trustee) ? true : false
        end
        
        def subject(role, trustee, parent = nil)
          trustee.authorize role, self, parent
        end
      
        def unsubject(role, trustee)
          trustee.unauthorize role, self
        end

        private        
        def get_auth_for_subject(role, trustee)
          trustee.authorizations.find(:first, :conditions => {:role => role, :subject_type => self.class.to_s, :subject_id => self.id})
        end
      end    
    end
    
  end
end