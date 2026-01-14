Rails.application.config.assets.version = "1.0"

# 1. Add ALL theme directories to the asset search paths.
# This allows Rails to find any file inside any theme's assets folder.
theme_root = Rails.root.join("app", "themes")

if Dir.exist?(theme_root)
  Dir.glob(theme_root.join("*")).each do |theme_dir|
    # Add stylesheets, javascripts, images, and fonts for every theme found
    %w[stylesheets javascripts images fonts].each do |asset_type|
      full_path = File.join(theme_dir, "assets", asset_type)
      Rails.application.config.assets.paths << full_path if Dir.exist?(full_path)
    end
  end
end

# 2. Precompile Global & Base Assets
Rails.application.config.assets.precompile += %w( fonts.css )
Rails.application.config.assets.precompile += %w( *.eot *.svg *.ttf *.woff *.woff2 )

# 3. Dynamically Precompile ALL Theme Entry Points
# This ensures that even if you add a new theme folder "Moria", 
# Rails will know to precompile "Moria.css" and "Moria.js" automatically.
if Dir.exist?(theme_root)
  # Precompile theme main CSS files (e.g., Hobbit.css, Dusk.css)
  theme_names = Dir.children(theme_root)
  theme_css = theme_names.map { |name| "#{name}.css" }
  theme_js  = theme_names.map { |name| "#{name}.js" }
  
  Rails.application.config.assets.precompile += theme_css
  Rails.application.config.assets.precompile += theme_js

  # Precompile all images found within any theme folder
  Rails.application.config.assets.precompile += Dir[
    theme_root.join("**", "assets", "images", "**", "*.{png,jpg,jpeg,gif,svg}")
  ].map { |path| File.basename(path) }
end