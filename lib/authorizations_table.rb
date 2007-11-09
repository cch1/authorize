require File.dirname(__FILE__) + '/identity'

# In order to use this mixin, you'll need the following:
# 1. An Authorization (Role) class with these associations:
#   belongs_to <Authorizee Class>
#   belongs_to <Model Class>
# 2. Database tables that support the roles. A sample migration is
#    supplied below
#
# create_table "authorizations", :force => true  do |t|
#   t.column :role,          :string, :limit => 20
#   t.column :trustee_id,    :integer
#   t.column :trustee_type,  :string, :limit => 25
#   t.column :subject_id,    :integer
#   t.column :subject_type,  :string, :limit => 25
#   t.column :created_at,    :datetime
#   t.column :updated_at,    :datetime
# end
# add_index :authorizations, [:role, :trustee_id, :trustee_type, :subject_id, :subject_type], :unique
# add_index :authorizations, [:trustee_id, :trustee_type, :subject_id, :subject_type, :role], :unique
# 
# As a result of including the authorizations option of ActsAsAuthorized, the following methods are available:
# 
# ActiveRecord-provided associations (see AR documentation for complete list of related methods)
#   Trustee (User or Group, for example)
#     authorizations
#           Returns array of authorizations belonging to trustee
#           Deprecated equivalent: roles
#     subjected_<subjected_models>   # Note the use of the plural model name
#           Returns authorized model objects
#           Not yet implemented
#   Subject (Widget, for example)
#     subjections  # Synonym for authorizations -must be distinct to permit model as both trustee and subject.
#           Returns array of authorizations over acts_as_subject objects.
#           Deprecated equivalent: accepted_roles
#     authorized_<trustee_models>
#           Returns array of trustees with an authorization over the acts_as_subject object.
#           Not yet implemented
#   Authorization
#     trustee
#           Returns the authorized trustee
#     subject
#           Returns the object of the authorization
#     subjected_<subjected_model>     # Note the use of the singular model name
#           Returns subjected model object of named class.  NB: This association is only safe with UUID-keyed models!
#           Disabled
#     authorized_<authorized_model>      # Note the use of the singular model name
#           Returns authorized trustee object of named class.  NB: This association is only safe with UUID-keyed trustees!
#           Disabled
# Standard ActsAsAuthorized methods:
#   Trustee
#     authorize <Role>, <Subject Instance or Class>
#           Creates an authorization for the trustee as <Role> over the subject Instance or Class.
#     unauthorize <Role>, <Subject Instance or Class>
#           Removes any authorization for the trustee as <Role> over the subject Instance or Class.
#     authorized? <Role>, <Subject Instance or Class>
#           Boolean condition for the trustee being authorized as the <Role> over the subject Instance or Class.
#   Subject (Authorizable Class or Instance)
#     subject <Role>, <Trustee>
#           Subjects the model instance or class to the authority of trustee as the named role.
#     unsubject <Role>, <Trustee>
#           Removes any authorization for the trustee as the named role over the model instance or class
#     subjected? <Role>, <Trustee>
#           Boolean condition for the the model Instance or Class being subjected to the authority of trustee as the named role.
# Identity Mixin methods:
#   Trustee
#     is_<Role>_for_what
#           Returns array of subjects for which trustee as <Role> is authorized
#     is_<Role>_<Preposition>?(<Authorizable object>)
#           Boolean condition for trustee as <Role> being authorized for the specified subject.
#     is_<Role>[_<Preposition> <Authorizable object>]
#           Creates authorization for trustee as <Role> either generically or over the specified subject (model or class)
#     is_<Role>
#           Creates generic authorization to trustee as <Role>
#   Subject
#     has_<Role>
#           Returns array of trustees having specified role over the subject.
#     has_<Role>?
#           Boolean conditioned upon at least one trustee having <Role> over the subject.

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
            logger.debug "#{User.current} authorizes #{self} as #{role} over #{subject} (derived from #{parent})"
            if subject.is_a? Class
              auth = self.authorizations.create(:role => role, :subject_type => subject.to_s, :parent => parent)
            elsif subject
              auth = self.authorizations.create(:role => role, :subject => subject, :parent => parent)
            else
              auth = self.authorizations.create(:role => role, :parent => parent)
            end
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
      ConditionClause = "EXISTS (SELECT a.* FROM authorizations a WHERE a.trustee_id IN (%s) AND (a.subject_type IS NULL OR (a.subject_type = '%s' AND (a.subject_id = %s.%s OR a.subject_id IS NULL)))%s)"
      # The above statement does not optimize well on MySQL 5.0, probably due to the presence of NULLs and ORs.  Forcing the use of an appropriate index solves the problem. 
#      ConditionClause = "EXISTS (SELECT a.* FROM authorizations a USE INDEX (authorizations_3) WHERE a.trustee_id IN (%s) AND (a.subject_type IS NULL OR (a.subject_type = '%s' AND (a.subject_id = %s.%s OR a.subject_id IS NULL)))%s)"

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
          conditions[:trustee_id] = trustee if trustee
          Authorization.find(:all, :conditions => conditions)
        end

        def authorized_conditions(roles = nil, trustees = User.current.identities)
          tlist = trustees.map {|t| '\'' + t.to_s + '\''}.join(',')
          if roles
            rlist = roles.map {|t| '\'' + t.to_s + '\''}.join(',')
            rclause = " AND a.role IN (%s)"% [rlist]
          end
          {:conditions => ConditionClause% [tlist, self, self.table_name, self.primary_key, rclause]}
        end
      
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
          trustees = options.delete(:trustees) || User.current.identities
          roles = options.delete(:roles)
          with_scope(:find => authorized_conditions(roles, trustees)) do
            count(column_name, options)
          end
        end
          
        def authorized_find(*args)
          options = args.last.is_a?(Hash) ? args.pop.dup : {}
          trustees = options.delete(:trustees) || User.current.identities
          roles = options.delete(:roles)
          with_scope(:find => authorized_conditions(roles, trustees)) do
            find(args.first, options)
          end
        end
        
        private          
        def get_auth_for_subject(role, trustee)
          trustee.authorizations.find(:first, :conditions => {:role => role, :subject_type => self.to_s, :subject_id => nil})
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