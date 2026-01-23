class ApplicationController < ActionController::Base
  # 1. Order matters: Set theme first, then use it for paths/helpers
  before_action :set_active_theme
  before_action :set_theme_view_path
  before_action :set_services
  before_action :load_menu
  before_action :set_active_storage_url_options

  helper_method :current_user, :current_theme

  private

  def set_active_theme
    # Use instance variable for request-local storage
    @active_theme = Setting.get("current-theme") || "Dusk"
    
    # Update the config if you use it elsewhere, though @active_theme is safer
    Rails.application.config.active_theme = @active_theme
  end

  def set_theme_view_path
    theme_path = Rails.root.join("app", "themes", @active_theme, "views")
    if Dir.exist?(theme_path)
      # prepend_view_path is smart enough not to add duplicates 
      # if you use the exact same Pathname object
      prepend_view_path(theme_path)
    end
  end

  # Safer way to include helpers dynamically for the current request
  def include_theme_helper
    module_name = "#{@active_theme}::Helpers::PagesHelper"
    helper_module = module_name.safe_constantize
    if helper_module
      # This makes the methods available in the view for this request
      view_context.extend(helper_module)
    end
  end

  # Helper method for use in controllers/views
  def current_theme
    @active_theme
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.base_url }
  end

  def set_services
    @services = Service.all
  end

  def load_menu
    @sidebar_menu_items = Menu.for_location('sidebar')&.order(:position) || []
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    
    unless current_user
      flash[:alert] = "You need to sign in to perform this action."
      redirect_to '/login'
    end
  end
end