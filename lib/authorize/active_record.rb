module Authorize
  module ActiveRecord
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def authorizable_trustee
        include Authorize::Trustee
        has_one :role, :class_name => "Authorize::Role", :as => :resource, :conditions => {:name => nil}, :dependent => :destroy
      end
  
      def authorizable_resource
        include Authorize::Resource
        has_many :permissions, :class_name => "Authorize::Permission", :as => :resource, :dependent => :delete_all
        reflection = reflections[:permissions]
        auth_fk = "#{reflection.quoted_table_name}.#{connection.quote_column_name(reflection.primary_key_name)}"
        resource_pk = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(primary_key)}"
        # See README file for a discussion of the performance of this named scope
        named_scope :permitted, lambda {|roles|
          scope = Permission.as(roles)
          sq0 = scope.construct_finder_sql({:select => 1, :conditions => {:resource_id => nil, :resource_type => nil}})
          sq1 = scope.construct_finder_sql({:select => 1, :conditions => {:resource_type => base_class.name, :resource_id => nil}})
          sq2 = scope.scoped(:conditions => "#{auth_fk} = #{resource_pk}").construct_finder_sql({:select => 1, :conditions => {:resource_type => base_class.name}})
          {:conditions => "EXISTS (#{sq0} UNION #{sq1} UNION #{sq2})"}
        }
      end
    end
  end
end