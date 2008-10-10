require File.join(File.dirname(__FILE__), 'boot')
require 'plugin_under_test_locator'

Rails::Initializer.run do |config|
  config.cache_classes = false
  config.whiny_nils = true

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/lib )

  # Make Rails use only this custom plugin locator to find the plugin under test -which is not in the usual location (there lies recursive madness)
  config.plugin_locators = [Rails::Plugin::Locator::PluginUnderTestLocator]

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_session',
    :secret      => '7e54ff5913c5c26e6389fad599134e255845d537650386fb04e5ed9c34aaeea4538a3c50833e1f243210c54d612a388afb11a6c876af18d9ac31f1be4fc78698'
  }
end
