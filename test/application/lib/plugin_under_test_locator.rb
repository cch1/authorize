module Rails
  class Plugin
    class Locator
      # Assists in the initialization process by locating the plugin being tested
      # so that it is tested as if the plugin were loaded in a regular app
      class PluginUnderTestLocator < Rails::Plugin::Locator
        def plugins
          path = File.expand_path(RAILS_ROOT + '../../..')
          [Rails::Plugin.new(path)]
        end
      end
    end
  end
end