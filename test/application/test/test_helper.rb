ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

# From this point forward, we can assume that we have booted a generic Rails environment plus
# our (booted) plugin.
load(File.dirname(__FILE__) + "/../db/schema.rb")

# Run the migrations (optional)
# ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")

# Set Test::Unit options for optimal performance/fidelity.
class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  set_fixture_class :permissions => Authorize::Permission

  def self.uses_mocha(description)
    require 'mocha'
    yield
  rescue LoadError
    $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
  end

  def self.test(name, &block)  # Shamelessly lifted from ActiveSupport
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end

# Unfortunately, setting expectations on any instance for #initialize causes #mocha_teardown
# to squirt out errors that cannot easily be suppressed in a less intrusive manner.
module Mocha
  module API
    def mocha_teardown_with_warning_suppression
      old_verbose, $VERBOSE = $VERBOSE, nil
      mocha_teardown_without_warning_suppression
      $VERBOSE = old_verbose
    end
    alias_method :mocha_teardown_without_warning_suppression, :mocha_teardown
    alias_method :mocha_teardown, :mocha_teardown_with_warning_suppression
  end
end

db = ::Redis.new.tap {|r| r.select 15}
raise "Test Database doesn't look safe" unless db.dbsize < 100
Authorize::Redis.db = db