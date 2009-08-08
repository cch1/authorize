# The Role model defines authorizations for users-as-role for a
# objects or classes. For example, you could create an authorization for a user as
# "moderator" for an instance of a class discussion, or for the Discussion class, or 
# generically (for all classes and objects).
class Authorization < ActiveRecord::Base
  belongs_to :subject, :polymorphic => true

  validates_presence_of :role
  validates_presence_of :token
  validates_presence_of :subject, :if => :subject_id
  
  named_scope :as, lambda {|roles| roles.nil? ? {} : {:conditions => {:role => roles}}}
  named_scope :with, lambda {|tokens| tokens.nil? ? {} : {:conditions => {:token => tokens}}}
  named_scope :for, lambda {|subject|
    subject_conditions = if subject.is_a?(NilClass) then
       {:subject_id => nil, :subject_type => nil}
    elsif subject.is_a?(Class) then
       {:subject_id => nil, :subject_type => subject.to_s}
    else
       {:subject_id => subject.id, :subject_type => subject.class.to_s}
    end
    {:conditions => subject_conditions}
  }

  ConditionClause = "token IN (?) OR EXISTS (SELECT 1 FROM authorizations a WHERE (a.subject_type IS NULL OR (a.subject_type = authorizations.subject_type AND (a.subject_id IS NULL OR a.subject_id = authorizations.subject_id))) AND a.token IN (?) AND a.role IN (?))"
  OwnershipRoles = %w(owner proxy)

  def self.generic_authorizations(tokens)
    self.find(:all, :conditions => {:subject_type => nil, :subject_id => nil, :token => tokens})
  end

  # Returns the effective authorizations for a subject. The subject can be any one of the following
  #   nil       generic/global authorizations are returned
  #   Class     generic/global and class authorizations are returned
  #   Instance  generic/global, class- subject-specific authorizations are returned.
  # The tokens and roles paramaters can be scalars or arrays.  The token elements can be AR objects or ids.
  def self.find_effective(subject = nil, tokens = nil, roles = nil)
    if subject.is_a?(NilClass) then
      subject_conditions = ["subject_type IS NULL"]
    elsif subject.is_a?(Class) then
      subject_conditions = ["subject_type IS NULL OR (subject_type = ? AND subject_id IS NULL)", subject.to_s]
    else
      subject_conditions = ["subject_type IS NULL OR (subject_type = ? AND (subject_id = ? OR subject_id IS NULL))", subject.class.to_s, subject]
    end
    self.with_scope(:find => {:conditions => subject_conditions}) do
      conditions = {}
      conditions[:token] = tokens if tokens
      conditions[:role] = roles if roles
      self.find(:all, :conditions => conditions)
    end
  end
  
  def self.authorized_conditions(tokens = default_identities, ownership_roles = nil)
    {:conditions => [ConditionClause, tokens, tokens, ownership_roles]}
  end
  
  # This method encapsulates an ugly-but-useful coupling between models and the User.current class method.
  # Override it to specify which tokens should be used by default to perform an authorized_{find, count}.
  def self.default_identities 
    raise Authorize::CannotObtainUserObject unless User && User.current 
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
    tokens = options.delete(:tokens) || default_identities
    with_scope(:find => authorized_conditions(tokens, options.delete(:roles))) do
      count(column_name, options)
    end
  end
    
  # Find the authorized authorizations.  An Authorization instance is considered authorized if the token is the token of the Authorization
  # instance, or if the token is the owner of the subject of the Authorization instance (where 'ownership' is determined by the roles option).  
  def self.authorized_find(*args)
    options = args.last.is_a?(Hash) ? args.pop.dup : {}
    tokens = options.delete(:tokens) || default_identities
    with_scope(:find => authorized_conditions(tokens, options.delete(:roles))) do
      find(args.first, options)
    end
  end
  
  def subj
    return '!Everything!' unless subject_type
    return subject_type.constantize unless subject_id
    return subject || '!Broken Link!'
  end

  def to_s
    "#{token} as #{role} over #{subj || '!Everything!'}"
  end
end
