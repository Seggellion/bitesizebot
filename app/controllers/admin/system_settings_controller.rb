# app/controllers/admin/system_settings_controller.rb
class Admin::SystemSettingsController < ApplicationController
  def update
    @setting = SystemSetting.instance

    # Identify if we are waking the bot up right now
    was_disabled = !@setting.bot_enabled?
    enabling = setting_params[:bot_enabled] == "true" || setting_params[:bot_enabled] == true

    # Merge the timestamp if we are transitioning to 'enabled'
    final_params = setting_params
    if was_disabled && enabling
      final_params = final_params.merge(last_enabled_at: Time.current)
    end

    if @setting.update(final_params)
      if was_disabled && @setting.bot_enabled?
        # Start the market loop if it's not already running
        MarketUpdateJob.perform_async
      end

      flash[:notice] = @setting.bot_enabled? ? "The bot has emerged from its burrow!" : "The bot is now napping."
    else
      flash[:alert] = "The magic failed to take hold."
    end

    redirect_to admin_root_path
  end

  private

  def setting_params
    params.require(:system_setting).permit(:bot_enabled, :bot_uid, :broadcaster_uid)
  end
end