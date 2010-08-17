module Authorize
  module ActiveRecord
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def authorizable_trustee
        include Authorize::Trustee
      end
  
      def authorizable_resource
        include Authorize::Resource
      end
    end
  end
end