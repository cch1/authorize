module Authorize
  module Trustee
    def self.included(recipient)
      recipient.has_one :primary_role, :class_name => "Authorize::Role", :as => :resource, :conditions => {:name => nil}, :dependent => :delete
    end

    def roles
      primary_role.roles
    end
  end
end