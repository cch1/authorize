class Widget < ActiveRecord::Base
  acts_as_subject

  def to_s
    name
  end
end