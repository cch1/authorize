module Authorize
  module Trustee
    def self.included(recipient)
      recipient.has_one :role, :class_name => "Authorize::Role", :as => :resource, :conditions => {:name => nil}, :dependent => :delete
    end
  end
end