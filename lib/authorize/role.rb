require 'authorize/redis'

class Authorize::Role < ActiveRecord::Base
  set_table_name 'authorize_roles'
  belongs_to :resource, :polymorphic => true
  has_many :permissions, :class_name => "Authorize::Permission", :dependent => :delete_all
  validates_uniqueness_of :name, :scope => [:resource_type, :resource_id]
  validates_uniqueness_of :relation, :scope => [:resource_type, :resource_id]
  after_create :create_vertex
  before_destroy :destroy_vertex

  named_scope :as, lambda{|relation| {:conditions => {:relation => relation}}}
  named_scope :identity, {:conditions => {:relation => nil}}

  GRAPH_ID = Authorize::Graph::DirectedAcyclicGraph.subordinate_key(Authorize::Role, 'graph')
  VERTICES_ID_PREFIX = Authorize::Graph::DirectedAcyclicGraph.subordinate_key(Authorize::Role, 'vertices')

  def self.const_missing(const)
    if global_role = scoped(:conditions => {:resource_type => nil, :resource_id => nil}).find_by_relation(const.to_s)
      const_set(const, global_role)
    else
      super
    end
  end

  def self.graph
    @graph ||= Authorize::Graph::DirectedGraph.load(GRAPH_ID).tap do |g|
      g.vertex_namespace = VERTICES_ID_PREFIX
    end
  end

  def create_vertex
    self.class.graph.vertex(id)
  end

  def destroy_vertex
    vertex.destroy
  end

  # Link from this role's vertex to other's vertex in the system role graph.  This role becomes the parent.
  def link(other)
    self.class.graph.join(nil, vertex, other.vertex)
  end

  # Unlink this role's vertex from other's vertex in the system role graph.
  def unlink(other)
    self.class.graph.disjoin(vertex, other.vertex)
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
    (name || "%s") % [relation, resource].compact.join(":") rescue "!! INVALID ROLE NAME !!"
  end

  def vertex
    raise 'Not possible to dereference vertex for an unpersisted role' unless id
    @vertex ||= self.class.graph.vertex_by_name(id)
  end

  def roles
    ids = traverser.map{|v| v.id.slice(/#{VERTICES_ID_PREFIX}::(\d+)/, 1)}
    self.class.find(ids).to_set
  end

  def descendants
    roles.delete(self)
  end

  def ancestors
    ids = reverse_traverser.map{|v| v.id.slice(/#{VERTICES_ID_PREFIX}::(\d+)/, 1)}
    ids -= [id.to_s]
    self.class.find(ids).to_set
  end

  private
  def traverser
    @traverser ||= Authorize::Graph::DirectedAcyclicGraphTraverser.traverse(vertex)
  end

  def reverse_traverser
    @reverse_traverser ||= Authorize::Graph::DirectedAcyclicGraphReverseTraverser.traverse(vertex)
  end
end
