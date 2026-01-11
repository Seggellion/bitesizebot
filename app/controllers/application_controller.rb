class ApplicationController < ActionController::Base
  # Load and include the static theme helper at class level
  begin
    theme_helpers_path = "#{Rails.application.config.active_theme || 'Dusk'}::Helpers::PagesHelper"
    helper_module = theme_helpers_path.constantize
    
    helper helper_module if helper_module
  rescue NameError => e
    Rails.logger.warn "Could not include theme helper #{theme_helpers_path}: #{e.message}"
  end

  before_action :set_active_theme            # must come before any theme usage
  before_action :set_services
  before_action :load_menu
  before_action :set_theme_view_path
  before_action :prepend_theme_paths
  before_action :set_active_storage_url_options

  helper_method :current_user, :current_theme

  private

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.base_url }
  end

  def set_services
    @services = Service.all
  end

  def load_menu
  @sidebar_menu_items = Menu.for_location('sidebar')&.order(:position) || []
   # @header_menu_items = Menu.for_location('header').order(:position)
   # @footer_menu_items = Menu.for_location('footer').order(:position)
  end

  def prepend_theme_paths
    prepend_view_path Rails.root.join("app", "themes", current_theme, "views")
  end

  def set_theme_view_path
    theme_path = Rails.root.join("app", "themes", current_theme, "views")
    prepend_view_path(theme_path) if File.directory?(theme_path)
  end

  def set_active_theme
    Rails.application.config.active_theme =
      Setting.get("current-theme") ||
      Rails.application.config.active_theme ||
      "Dusk"
  end


  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def authenticate_user!
  unless current_user
    flash[:alert] = "You need to sign in to perform this action."
    redirect_to '/login' # or whatever your login path is
  end
end


  def current_theme
    Rails.application.config.active_theme || 'Dusk'
  end
end
