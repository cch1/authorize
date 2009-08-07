config.after_initialize do
  require 'db/schema.rb'
  require 'active_record/fixtures'
  Fixtures.create_fixtures('test/fixtures', [:users, :widgets, :authorizations])  
end