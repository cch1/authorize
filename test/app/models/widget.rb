class Widget < ActiveRecord::Base
  acts_as_subject
  authorizable_resource

  def to_s
    name
  end
end