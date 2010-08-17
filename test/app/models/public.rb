require 'singleton'

# This is an example of a non-ActiveRecord trustee
class Public
  include Singleton

  def role
    Authorize::Role.find_by_name('Public')
  end

  def to_s
    "Public"
  end
end