# app/controllers/admin/users_controller.rb
module Admin
    class UsersController < ApplicationController
      before_action :require_admin
      before_action :set_user, only: [:edit, :update]
  
      def index
@users = User.order(updated_at: :desc)
      end
  
      def edit
        # The @user instance variable is set by the set_user method
      end
  
      def update        
        if @user.update(user_params)
          
          if @user.user_type == "bot"
            SystemSetting.instance.update!(bot_uid: @user.uid)
          elsif @user.username == Setting.get("broadcaster_username")
            SystemSetting.instance.update!(broadcaster_uid: @user.uid)
          end
          redirect_to admin_users_path, notice: 'User was successfully updated.'
        else
          render :edit
        end
      end

      def toggle_giveaway_ban
        @user = User.find(params[:id])
        tag = Tag.find_or_create_by!(name: 'giveaway_banned')
        
        tagging = @user.taggings.find_by(tag: tag)

        if tagging
          tagging.destroy
          message = "Giveaway ban removed for #{@user.username}."
        else
          @user.taggings.create!(tag: tag)
          message = "Giveaway ban applied for #{@user.username}."
        end

        redirect_back fallback_location: admin_user_path(@user), notice: message
      end
  
      private
  
      def set_user
        @user = User.find(params[:id])
      end
  
      def user_params
        params.require(:user).permit(:name, :user_type)
      end
    end
  end
  