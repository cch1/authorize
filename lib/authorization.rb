# The Role model defines authorizations for users-as-role for a
# objects or classes. For example, you could create an authorization for a user as
# "moderator" for an instance of a class discussion, or for the Discussion class, or 
# generically (for all classes and objects).
class Authorization < ActiveRecord::Base
  belongs_to :trustee, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  
  validates_presence_of :role
  validates_presence_of :trustee_type
  validates_presence_of :trustee_id

  ConditionClause = "trustee_id IN (%s) OR EXISTS (SELECT id FROM authorizations a WHERE a.subject_id = authorizations.subject_id AND a.subject_type = authorizations.subject_type AND a.role IN (%s) AND a.trustee_id IN (%s))"
  OwnershipRoles = %w(owner proxy)

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
  
  def self.authorized_conditions(roles = nil, trustees = User.current.identities)
    rlist = (roles || OwnershipRoles).map{|r| "'#{r}'"}.join(',')
    tlist = trustees.map{|t| "'#{t}'"}.join(',')
    {:conditions => ConditionClause% [tlist, rlist, tlist]}
  end
  
  def self.authorized_count(*args)
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
    
  def self.authorized_find(*args)
    options = args.last.is_a?(Hash) ? args.pop.dup : {}
    trustees = options.delete(:trustees) || User.current.identities
    roles = options.delete(:roles)
    with_scope(:find => authorized_conditions(roles, trustees)) do
      find(args.first, options)
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
