module Authorize
  module Trustee
    def self.included(recipient)
      recipient.has_one :primary_role, :class_name => "Authorize::Role", :as => :resource, :conditions => {:name => nil}, :dependent => :delete
    end

    def roles
      ::Set[primary_role]
    end
  end
end