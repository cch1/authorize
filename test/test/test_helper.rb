ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

# Set Test::Unit options for optimal performance/fidelity.
class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  set_fixture_class :permissions => Authorize::Permission, :roles => Authorize::Role

  def self.uses_mocha(description)
    require 'mocha'
    yield
  rescue LoadError
    $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
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

raise "Test Database doesn't look safe" unless Authorize::Redis::Base.db.dbsize < 200