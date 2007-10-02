# The Role model defines authorizations for users-as-role for a
# objects or classes. For example, you could create an authorization for a user as
# "moderator" for an instance of a class discussion, or for the Discussion class, or 
# generically (for all classes and objects).
class Authorization < ActiveRecord::Base
  belongs_to :trustee, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  
  acts_as_tree
  
  validates_presence_of :role
#  validates_presence_of :subject_type, :on => :create, :if => Proc.new { |a| not (a.trustee_id == 1 && a.trustee_type == 'User') }
#  validates_presence_of :subject_id, :on => :create, :if => Proc.new { |a| not (a.trustee_id == 1 && a.trustee_type == 'User') }
  validates_presence_of :trustee_type
  validates_presence_of :trustee_id

  ConditionClause = "trustee_id IN (%s) OR EXISTS (SELECT id FROM authorizations a WHERE a.subject_id = authorizations.subject_id AND a.subject_type = authorizations.subject_type AND a.role IN (%s) AND a.trustee_id IN (%s))"

  def self.generic_authorizations(trustee)
    self.find(:all, :conditions => {:subject_type => nil, :subject_id => nil, :trustee_id => trustee})
  end
  
  # Returns the effective authorizations over a subject.
  # The trustee and role paramaters can be scalars or arrays.  The trustee elements 
  # can be AR objects or ids.
  def self.find_effective(subject, trustee = nil, role = nil)
    subject_conditions = "subject_type IS NULL OR (subject_type = '%s' AND (subject_id = '%s' OR subject_id IS NULL))"% [subject.class.to_s, subject.id]
    self.with_scope(:find => {:conditions => subject_conditions}) do
      conditions = {}
      conditions[:trustee_id] = trustee if trustee
      conditions[:role] = role if role
      options = {}
      options[:conditions] = conditions if !conditions.empty?
      self.find(:all, options)
    end
  end
  
  def self.authorized_conditions(trustees = [User.current.id], roles = %w(owner proxy))
    rlist = roles.map{|r| "'#{r}'"}.join(',')
    tlist = trustees.map{|t| "'#{t}'"}.join(',')
    {:conditions => ConditionClause% [tlist, rlist, tlist]}
  end
  
  def self.authorized_count(*args)
    with_scope(:find => self.authorized_conditions) do
      self.count(*args)
    end
  end
    
  def self.authorized_find(*args)
    with_scope(:find => self.authorized_conditions) do
      self.find(*args)
    end
  end
  
  def subj
    return '!Everything!' unless subject_type
    return subject_type.constantize unless subject_id
    return subject || '!Broken Link!'
  end
  
  def broken_link?
    subject.nil? && !subject_id.nil?
  end
  
  def to_s
    "#{trustee} as #{role} over #{subj || '!Everything!'}"
  end
end
