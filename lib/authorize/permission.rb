require 'authorize/bitmask'

class Authorize::Permission < ActiveRecord::Base
  class Mask < Authorize::Bitmask
    self.name_values = {:list => 1, :read => 2, :update => 4, :delete => 8, :add => 16, :remove => 32, :manage => 64, :all => 127}
  end

  set_table_name 'authorize_permissions'
  # This is of questionable value given the specific implementation of mask attribute methods.  It also requires
  # table inspection, so we skip it if the table does not yet exist.
  cache_attributes('mask') if table_exists?

  belongs_to :_resource, :polymorphic => true, :foreign_type => 'resource_type', :foreign_key => 'resource_id'
  belongs_to :role, :class_name => "Authorize::Role"
  validates_presence_of :role
  validates_presence_of :resource

  before_save :set_mandatory_list_mode

  # Returns the explicit authorizations over a subject. The resource can be any one of the following
  #   Object                global permissions are returned
  #   <Resource Class>      global and class permissions are returned
  #   <Resource Instance>   global, class and instance permissions are returned
  # This exists to simplify finding and creating global and class permissions.  For resource instance
  # permissions, use the standard Rails association (#permissions) created for authorizable resources.
  named_scope :for, lambda {|resource|
    resource_conditions = if (resource == Object) then
       {:resource_id => nil, :resource_type => nil}
    elsif resource.is_a?(Class) then
       {:resource_id => nil, :resource_type => resource.to_s}
    else
       {:resource_id => resource.id, :resource_type => resource.class.to_s}
    end
    {:conditions => resource_conditions}
  }
  # Returns the effective permissions over a resource.
  named_scope :over, lambda {|resource|
    resource_conditions = if (resource == Object) then
       {:resource_id => nil, :resource_type => nil}
    elsif resource.is_a?(Class) then
      c1 = sanitize_sql_hash_for_conditions(:resource_type => nil)
      c2 = sanitize_sql_hash_for_conditions(:resource_type => resource.base_class.name, :resource_id => nil)
      "#{c1} OR (#{c2})"
    else
      c1 = sanitize_sql_hash_for_conditions(:resource_type => nil)
      c2 = sanitize_sql_hash_for_conditions(:resource_type => resource.class.base_class.name)
      c3 = sanitize_sql_hash_for_conditions(:resource_id => resource.quoted_id)
      c4 = sanitize_sql_hash_for_conditions(:resource_id => nil)
      "#{c1} OR (#{c2} AND (#{c3} OR #{c4}))"
    end
    {:conditions => resource_conditions}
  }
  named_scope :as, lambda {|roles| {:conditions => {:role_id => roles.map(&:id)}}}
  named_scope :global, :conditions => {:resource_type => nil, :resource_id => nil}

  # Find the effective permissions over a given resource for a given set of role_ids
  def self.effective(resource, roles)
    over(resource).as(roles)
  end

  # Find the effective permission mask over a given resource for a given set of role_ids
  def self.effective_mask(*args)
    effective(*args).inject(Mask.new){|memo, p| memo.merge(p.mask)}.complete
  end

  # Because the list mode is always assumed to be set for performance, we expose that assumption explicitly.
  def set_mandatory_list_mode
    self['mask'] |= Mask.name_values[:list]
    @attributes_cache.delete('mask')
  end

  # Virtual attribute that expands the common belongs_to association with a three-level hierarchy
  def resource
    return Object unless resource_type
    return resource_type.constantize unless resource_id
    return _resource
  end

  def resource=(res)
    return self._resource = res unless res.kind_of?(Class)
    self.resource_id = nil
    return self[:resource_type] = nil if res == Object
    return self[:resource_type] = res.to_s
  end

  def mask(reload = false)
    cached = @attributes_cache['mask'] # undocumented hash of cache nicely invalidated by write_attribute
    return cached if cached && !reload
    @attributes_cache['mask'] = Mask.new(read_attribute('mask')) # Ensure we always return a Mask instance
  end

  def to_s(reduce = true)
    "#{role} over #{resource} (#{mask})"
  end
end