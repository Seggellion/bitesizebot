require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module Railpress
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    config.active_theme = ENV["ACTIVE_THEME"] || "Dusk"

    config.autoload_paths << Rails.root.join('app', 'themes')
    config.eager_load_paths << Rails.root.join('app', 'themes')




    config.autoload_lib(ignore: %w[assets tasks])

  end
end
