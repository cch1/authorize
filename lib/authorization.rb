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

  ConditionClause = "trustee_id IN (?) OR EXISTS (SELECT 1 FROM authorizations a WHERE (a.subject_type IS NULL OR (a.subject_type = authorizations.subject_type AND (a.subject_id IS NULL OR a.subject_id = authorizations.subject_id))) AND a.trustee_id IN (?) AND a.role IN (?))"
  OwnershipRoles = %w(owner proxy)

  def self.generic_authorizations(trustee)
    self.find(:all, :conditions => {:subject_type => nil, :subject_id => nil, :trustee_id => trustee})
  end
  
  # Returns the effective authorizations (generic/global, class and subject-specific authorizations) for a subject instance.
  # The trustee and role paramaters can be scalars or arrays.  The trustee elements 
  # can be AR objects or ids.
  def self.find_effective(subject, trustee = nil, role = nil)
    subject_conditions = ["subject_type IS NULL OR (subject_type = ? AND (subject_id = ? OR subject_id IS NULL))", subject.class.to_s, subject.id]
    self.with_scope(:find => {:conditions => subject_conditions}) do
      conditions = {}
      conditions[:trustee_id] = trustee if trustee
      conditions[:role] = role if role
      self.find(:all, :conditions => conditions)
    end
  end
  
  def self.authorized_conditions(trustees = default_identities, ownership_roles = nil)
    {:conditions => [ConditionClause, trustees, trustees, ownership_roles]}
  end
  
  # This method encapsulates an ugly-but-useful coupling between models and the User.current class method.
  # Override it to specify which trustees should be used by default to perform an authorized_{find, count}.
  def self.default_identities 
    raise CannotObtainUserObject unless User && User.current 
    User.current.respond_to?(:identities) ? User.current.identities : [User.current]
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
    trustees = options.delete(:trustees) || default_identities
    with_scope(:find => authorized_conditions(trustees, options.delete(:roles))) do
      count(column_name, options)
    end
  end
    
  # Find the authorized authorizations.  An Authorization instance is considered authorized if the trustee is the trustee of the Authorization
  # instance, or if the trustee is the owner of the subject of the Authorization instance (where 'ownership' is determined by the roles option).  
  def self.authorized_find(*args)
    options = args.last.is_a?(Hash) ? args.pop.dup : {}
    trustees = options.delete(:trustees) || default_identities
    with_scope(:find => authorized_conditions(trustees, options.delete(:roles))) do
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
