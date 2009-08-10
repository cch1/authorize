require 'parser'
require 'authorize'
require 'authorizations_table'
require 'GroupSmarts/authorize/exceptions'

ActionController::Base.send(:include, Authorize::Base)
ActionView::Base.send(:include, Authorize::Base::ControllerInstanceMethods)
ActiveRecord::Base.send(:include, Authorize::AuthorizationsTable::TrusteeExtensions, Authorize::AuthorizationsTable::SubjectExtensions)
