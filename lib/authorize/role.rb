require 'authorize/redis'

class Authorize::Role < ActiveRecord::Base
  set_table_name 'authorize_roles'
  belongs_to :_resource, :polymorphic => true, :foreign_type => 'resource_type', :foreign_key => 'resource_id'
  has_many :permissions, :class_name => "Authorize::Permission", :dependent => :delete_all
  validates_uniqueness_of :name, :scope => [:resource_type, :resource_id]

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

  def to_s
    (name || "%s") % resource rescue "!! INVALID ROLE NAME !!"
  end
  
  def children
    raise "Not Yet Implemented"
  end
  
  def parents
    raise "Not Yet Implemented"
  end
end