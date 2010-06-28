module Authorize
  module AuthorizationsTable

    module TrusteeExtensions
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_trustee(key = :authorization_token)
          if key
            define_method(:permissions) do
              token = send(key)
              Authorization.with(token).scoped(:conditions => {:trustee_type => self.class.base_class.name})
            end
            before_destroy do |trustee|
              trustee.permissions.delete_all
            end
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
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_subject
          has_many :subjections, :as => :subject, :class_name => 'Authorization', :dependent => :delete_all
          include Authorize::AuthorizationsTable::SubjectExtensions::InstanceMethods
          include Authorize::Identity::SubjectExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
          extend Authorize::AuthorizationsTable::SubjectExtensions::SingletonMethods
          reflection = reflections[:subjections]
          # See README file for a discussion of the performance of this named scope
          auth_fk = "#{reflection.quoted_table_name}.#{connection.quote_column_name(reflection.primary_key_name)}"
          subject_pk = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(primary_key)}"
          named_scope :authorized, lambda {|tokens, roles|
            scope = Authorization.with(tokens).as(roles)
            sq0 = scope.construct_finder_sql({:select => 1, :conditions => {:subject_id => nil, :subject_type => nil}})
            sq1 = scope.construct_finder_sql({:select => 1, :conditions => {:subject_type => base_class.name, :subject_id => nil}})
            sq2 = scope.scoped(:conditions => "#{auth_fk} = #{subject_pk}").construct_finder_sql({:select => 1, :conditions => {:subject_type => base_class.name}})
            {:conditions => "EXISTS (#{sq0} UNION #{sq1} UNION #{sq2})"}
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