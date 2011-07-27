module Authorize
  module ActiveRecord
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end

    module ClassMethods
      def authorizable_trustee(options = {})
        include Authorize::Trustee
        # The "identity" role -the single role that represents this trustee.  It is also the root vertex for collecting
        # the set of roles belonging to the trustee.
        has_one :role, :class_name => "Authorize::Role", :as => :resource, :conditions => {:relation => nil}, :dependent => :destroy
        after_create {|trustee| trustee.create_role(:name => options[:name])}
      end

      def authorizable_resource
        include Authorize::Resource
        has_many :permissions, :class_name => "Authorize::Permission", :as => :resource, :dependent => :delete_all
        # The roles that represent relations/associations of a resource
        has_many :roles, :class_name => "Authorize::Role", :as => :resource
        reflection = reflections[:permissions]
        auth_fk = "#{reflection.quoted_table_name}.#{connection.quote_column_name(reflection.primary_key_name)}"
        resource_pk = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(primary_key)}"
        # See README file for a discussion of the performance of this named scope
        named_scope :permitted, lambda {|*args|
          roles = args.shift
          options = {:modes => []}.merge(args.last.kind_of?(Hash) ? args.pop : {})
          modes = args + options[:modes]
          modes << options[:mode] if options[:mode]
          scope = Permission.as(roles)
          scope = scope.to_do(Authorize::Permission::Mask[*modes]) unless modes.empty?
          sq0 = scope.construct_finder_sql({:select => 1, :conditions => {:resource_id => nil, :resource_type => nil}})
          sq1 = scope.construct_finder_sql({:select => 1, :conditions => {:resource_type => base_class.name, :resource_id => nil}})
          sq2 = scope.scoped(:conditions => "#{auth_fk} = #{resource_pk}").construct_finder_sql({:select => 1, :conditions => {:resource_type => base_class.name}})
          {:conditions => "EXISTS (#{sq0} UNION #{sq1} UNION #{sq2})"}
        }
      end
    end
  end
end
