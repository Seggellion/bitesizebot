# app/controllers/admin/users_controller.rb
module Admin
    class UsersController < ApplicationController
      before_action :require_admin
      before_action :set_user, only: [:edit, :update, :toggle_giveaway_ban]
  
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
      
        ban_tag = Tag.find_or_create_by(name: 'giveaway_banned')

        if @user.tags.include?(ban_tag)
          # Unban logic
          @user.tags.delete(ban_tag)
          flash[:notice] = "User #{@user.username} is no longer banned from winning giveaways."
        else
          # Ban logic
          @user.tags << ban_tag
          flash[:alert] = "User #{@user.username} has been silently banned from winning giveaways."
        end

        # Redirect back to the user list (preserving scroll position/page if possible)
        redirect_back(fallback_location: root_path)
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
  