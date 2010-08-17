class ApplicationController < ActionController::Base
  def roles
    Set[Public.instance.role]
  end
end