# The Role model defines authorizations for users-as-role for a
# objects or classes. For example, you could create an authorization for a user as
# "moderator" for an instance of a class discussion, or for the Discussion class, or 
# generically (for all classes and objects).
class Authorization < ActiveRecord::Base
  ConditionClause = "token IN (?) OR EXISTS (SELECT 1 FROM authorizations a WHERE (a.subject_type IS NULL OR (a.subject_type = authorizations.subject_type AND (a.subject_id IS NULL OR a.subject_id = authorizations.subject_id))) AND a.token IN (?) AND a.role IN (?))"

  belongs_to :subject, :polymorphic => true

  validates_presence_of :role
  validates_presence_of :token
  validates_presence_of :subject, :if => :subject_id
  
  named_scope :as, lambda {|roles| {:conditions => {:role => roles}}}
  named_scope :with, lambda {|tokens| {:conditions => {:token => tokens}}}
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
  # Returns the effective authorizations over a subject. The subject can be any one of the following
  #   nil       generic/global authorizations are returned
  #   Class     generic/global and class authorizations are returned
  #   Instance  generic/global, class authorizations and subject authorizations are returned.
  named_scope :over, lambda {|subject|
    subject_conditions = if subject.is_a?(NilClass) then
       {:subject_id => nil, :subject_type => nil}
    elsif subject.is_a?(Class) then
      ["subject_type IS NULL OR (subject_type = ? AND subject_id IS NULL)", subject.to_s]
    else
      ["subject_type IS NULL OR (subject_type = ? AND (subject_id = ? OR subject_id IS NULL))", subject.class.to_s, subject]
    end
    {:conditions => subject_conditions}
  }
  named_scope :generic, :conditions => {:subject_type => nil, :subject_id => nil}
  named_scope :authorized, lambda {|tokens, roles|
    {:conditions => [ConditionClause, tokens, tokens, roles]}
  }

  # Find the effective authorizations (including authorizations inherited from global or relevant class authorizations) over a given subject.
  # A nil subject implies a search for global authorizations.
  # A nil token argument or a nil role argument ignores the corresponding attribute.
  # The tokens and roles paramaters can be scalars or arrays.  The token elements can be strings or string-like objects.
  def self.find_effective(subject, tokens = nil, roles = nil)
    scope = over(subject)
    scope = scope.as(roles) if roles
    scope = scope.with(tokens) if tokens
    scope.all
  end
  
  def subj
    return nil unless subject_type
    return subject_type.constantize unless subject_id
    return subject || '!Broken Link!'
  end

  def to_s
    "#{token} as #{role} over #{subj || '!Everything!'}"
  end
end
