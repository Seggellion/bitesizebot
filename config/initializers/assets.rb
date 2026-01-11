# Be sure to restart your server when you modify this file.

Rails.application.config.assets.version = "1.0"

# Precompile theme-specific manifest
Rails.application.config.assets.precompile += [
  "#{Rails.application.config.active_theme}/assets/config/manifest.js.erb"
]

# Add theme asset paths
Rails.application.config.assets.paths << Rails.root.join("app", "themes", Rails.application.config.active_theme, "assets", "stylesheets")
Rails.application.config.assets.paths << Rails.root.join("app", "themes", Rails.application.config.active_theme, "assets", "javascripts")

Rails.application.config.assets.paths << Rails.root.join("app", "themes", Rails.application.config.active_theme, "assets", "fonts")


theme_path = Rails.root.join("app", "themes", Rails.application.config.active_theme, "assets", "images")

Rails.application.config.assets.paths << theme_path

Rails.application.config.assets.precompile += Dir["#{theme_path}/**/*.{png,jpg,jpeg,gif,svg}"].map do |path|
  # Convert full path to logical asset path
  Pathname.new(path).relative_path_from(theme_path).to_s
end

# Fonts and base assets
Rails.application.config.assets.precompile += %w( fonts.css )
Rails.application.config.assets.precompile += %W( #{Rails.application.config.active_theme}.css )
Rails.application.config.assets.precompile += %w( *.eot *.svg *.ttf *.woff *.woff2 )

# ✅ Dynamically precompile all images from the active theme
Rails.application.config.assets.precompile += Dir[
  Rails.root.join("app", "themes", Rails.application.config.active_theme, "assets", "images", "**", "*.{png,jpg,jpeg,gif,svg}")
].map { |path|
  Pathname.new(path).basename.to_s
}

