require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module Railpress
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    
    config.load_defaults 8.0
    config.active_theme = "Dusk"
    config.assets.paths << Rails.root.join("app", "themes")
    config.autoload_paths << Rails.root.join('app', 'themes')
    config.eager_load_paths << Rails.root.join('app', 'themes')

    config.active_job.queue_adapter = :sidekiq


    config.autoload_lib(ignore: %w[assets tasks])

  end
end
