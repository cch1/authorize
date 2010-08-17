require 'authorize/redis'

class Authorize::Role < ActiveRecord::Base
  set_table_name 'authorize_roles'
  belongs_to :_resource, :polymorphic => true, :foreign_type => 'resource_type', :foreign_key => 'resource_id'
  has_many :permissions, :class_name => "Authorize::Permission", :dependent => :delete_all
  validates_uniqueness_of :name, :scope => [:resource_type, :resource_id]
  after_save :create_vertex
  # TODO: after_destroy to delete vertex and associated edges

  # This exists to simplify finding and creating global and class-level roles.  For resource instance-related
  # roles, use the standard Rails association (#roles) created for authorizable resources.
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
  named_scope :global, :conditions => {:resource_type => nil, :resource_id => nil}
  named_scope :identity, :conditions => {:name => nil}

  def self.graph
    @graph ||= Authorize::Graph.load('Authorize::Role::graph')
  end

  def create_vertex
    self.class.graph.vertex("Authorize::Role::vertices::#{id}")
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

  def to_s
    (name || "%s") % resource rescue "!! INVALID ROLE NAME !!"
  end

  def vertex
    raise 'Not possible to dereference vertex for an unpersisted role' unless id
    @vertex ||= Authorize::Graph::Vertex.load("Authorize::Role::vertices::#{id}")
  end

  def roles
    ids = vertex.traverse.map{|v| v.id.slice(/.*::(\d+)/, 1) }
    self.class.find(ids).to_set
  end

  def children
    roles.delete(self)
  end

  def parents
    raise "Not Yet Implemented"
  end
end