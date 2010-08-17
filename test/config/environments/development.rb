config.after_initialize do
  require 'active_record/fixtures'
  Fixtures.create_fixtures('test/fixtures', [:users, :widgets, :permissions, :roles], :permissions => Authorize::Permission, :roles => Authorize::Role)
end