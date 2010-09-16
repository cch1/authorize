require 'authorize/redis'

class Authorize::Role < ActiveRecord::Base
  set_table_name 'authorize_roles'
  belongs_to :resource, :polymorphic => true
  has_many :permissions, :class_name => "Authorize::Permission", :dependent => :delete_all
  validates_uniqueness_of :name, :scope => [:resource_type, :resource_id]
  validates_uniqueness_of :relation, :scope => [:resource_type, :resource_id]
  after_create :create_vertex
  # TODO: after_destroy to delete vertex and associated edges

  named_scope :as, lambda{|relation| {:conditions => {:relation => relation}}}
  named_scope :identity, {:conditions => {:relation => nil}}

  GRAPH_ID = Authorize::Graph.subordinate_key(Authorize::Role, 'graph')
  VERTICES_ID_PREFIX = Authorize::Graph.subordinate_key(Authorize::Role, 'vertices')

  def self.graph
    @graph ||= Authorize::Graph.load(GRAPH_ID)
  end

  def create_vertex
    self.class.graph.vertex(vertex_id)
  end

  # Link from this role's vertex to other's vertex in the system role graph.  This role becomes the parent.
  def link(other)
    self.class.graph.edge(nil, vertex, other.vertex)
  end

  # Creates or updates the unique permission for a given resource to have the given modes
  # Example:  public.may(:list, :read, widget)
  def may(*args)
    p = permissions.for(args.pop).find_or_initialize_by_role_id(id) # need a #find_or_initialize_by_already_specified_scope
    p.mask += Authorize::Permission::Mask[*args]
    p.save
    p.mask.complete
  end

  # Updates or deletes the unique permission for a given resource to not have the given modes
  # Example:  public.may_not(:update, widget)
  def may_not(*args)
    p = permissions.for(args.pop).first
    return Authorize::Permission::Mask[] unless p
    p.mask -= Authorize::Permission::Mask[*args].complete
    p.mask.empty? ? p.destroy : p.save
    p.mask.complete
  end

  # Test if all given modes are permitted for the given resource
  def may?(*args)
    return false unless p = permissions.for(args.pop).first
    mask = Authorize::Permission::Mask[*args].complete
    mask.subset?(p.mask)
  end

  # Test if none of the given modes are permitted for the given resource
  def may_not?(*args)
    return true unless p = permissions.for(args.pop).first
    mask = Authorize::Permission::Mask[*args].complete
    (mask & p.mask).empty?
  end

  def to_s
    (name || "%s") % resource rescue "!! INVALID ROLE NAME !!"
  end

  def vertex
    raise 'Not possible to dereference vertex for an unpersisted role' unless id
    @vertex ||= Authorize::Graph::Vertex.load(vertex_id)
  end

  def roles
    ids = vertex.traverse.map{|v| v.id.slice(/#{VERTICES_ID_PREFIX}::(\d+)/, 1) }
    self.class.find(ids).to_set
  end

  def children
    roles.delete(self)
  end

  def parents
    raise "Not Yet Implemented"
  end

  private
  def vertex_id
    @vertex_id ||= Authorize::Graph::Vertex.subordinate_key(VERTICES_ID_PREFIX, id)
  end
end