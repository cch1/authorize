require 'parser'
require 'authorize'
require 'authorizations_table'
require 'exceptions'

ActionController::Base.send(:include, Authorize::Base)
ActionView::Base.send(:include, Authorize::Base::ControllerInstanceMethods)
ActiveRecord::Base.send(:include, Authorize::AuthorizationsTable, Authorize::AuthorizationsTable::TrusteeExtensions, Authorize::AuthorizationsTable::ModelExtensions)
