#RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.cache_classes = false
  config.whiny_nils = true

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/lib )

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_session',
    :secret      => '7e54ff5913c5c26e6389fad599134e255845d537650386fb04e5ed9c34aaeea4538a3c50833e1f243210c54d612a388afb11a6c876af18d9ac31f1be4fc78698'
  }

  config.after_initialize do
    ActiveRecord::Migration.verbose = false
    require File.join(RAILS_ROOT, "db", 'schema.rb')
  end
end