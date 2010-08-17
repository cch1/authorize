class User < ActiveRecord::Base
  authorizable_trustee
  authorizable_resource

  def to_s
    login
  end
end