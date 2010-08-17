require 'authorize/base'
require 'authorize/exceptions'

ActionController::Base.send(:include, Authorize::Base)
ActiveRecord::Base.send(:include, Authorize::AuthorizationsTable::TrusteeExtensions, Authorize::AuthorizationsTable::SubjectExtensions)
ActionView::Base.send(:include, Authorize::HelperMethods)