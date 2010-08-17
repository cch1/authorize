require 'authorize/exceptions'

ActiveRecord::Base.send(:include, Authorize::ActiveRecord)
ActionController::Base.send(:include, Authorize::ActionController)
ActionView::Base.send(:include, Authorize::ActionView)