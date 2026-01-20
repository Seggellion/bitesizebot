# app/controllers/admin/system_settings_controller.rb
class Admin::SystemSettingsController < ApplicationController
def update
    @setting = SystemSetting.instance

    was_disabled = !@setting.bot_enabled?
    
    if @setting.update(setting_params)

    if was_disabled && @setting.bot_enabled?
      MarketUpdateJob.perform_async
    end

      flash[:notice] = @setting.bot_enabled? ? "The bot has emerged from its burrow!" : "The bot is now napping."
    else
      flash[:alert] = "The magic failed to take hold."
    end

    # Redirecting is the secret sauce here. 
    # Turbo will see the redirect and update the page automatically.
    redirect_to admin_root_path
  end


  private

  def setting_params
    # Ensure bot_enabled is cast to a boolean properly
    params.require(:system_setting).permit(:bot_enabled,:bot_uid, :broadcaster_uid)
  end
end