require 'test/unit'

# Boot Rails manually, instead of via the environment.rb file.  This help limit the impact of the host application.
# Plugins are booted as a consequence of booting Rails.
ENV['RAILS_ENV'] = 'test'
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION
require File.expand_path(File.join(File.dirname(__FILE__) + '/../../../../config/boot.rb'))
Rails::Initializer.run

# Remove the host application (../app/...) from the dependency and load paths.
ActiveSupport::Dependencies.load_paths.delete_if {|path| /app\//.match(path) }
ActiveSupport::Dependencies.load_once_paths.delete_if {|path| /app\//.match(path) }
$LOAD_PATH.delete_if {|path| /app\//.match(path) }

# Add our testing library directory to the load path.
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

db_adapter = ENV['DB']
# no db passed, try one of these fine config-free DBs before bombing. 
db_adapter ||= 
  begin
    require 'rubygems'
    require 'sqlite'
    'sqlite'
  rescue MissingSourceFile
    begin 
      require 'sqlite3'
      'sqlite3'
    rescue MissingSourceFile
    end
  end

if db_adapter.nil?
  raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3." 
end

db_config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(db_config[db_adapter])

load(File.dirname(__FILE__) + "/schema.rb")

require 'action_controller/test_process'

require 'active_record/fixtures'
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures"

class Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end