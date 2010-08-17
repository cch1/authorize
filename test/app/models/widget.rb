class Widget < ActiveRecord::Base
  authorizable_resource

  def to_s
    name
  end
end