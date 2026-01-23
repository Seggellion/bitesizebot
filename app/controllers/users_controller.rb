class UsersController < ApplicationController
    before_action :set_user, only: [:edit_minecraft_uuid, :update_minecraft_uuid, :toggle_giveaway_ban]
  
    # Display the form
    def edit_minecraft_uuid
    end

  
    # Handle form submission
    def update_minecraft_uuid
      username = params[:user][:username]
  
      # Send request to third-party API
      uuid = fetch_minecraft_uuid(username)
  
      if uuid
        # Update user attributes
        if @user.update(minecraft_uuid: uuid, username: username)
        update_minecraft_avatar(@user)
          redirect_to @user, notice: 'Minecraft UUID and username were successfully updated.'
        else
          flash.now[:alert] = 'Failed to update user.'
          render :edit_minecraft_uuid
        end
      else
        flash.now[:alert] = 'Failed to fetch Minecraft UUID. Please try again.'
        render :edit_minecraft_uuid
      end
    end
  
    private
  

    def get_minecraft_skin_url(uuid)
        url = "https://sessionserver.mojang.com/session/minecraft/profile/#{uuid}"
        response = Net::HTTP.get(URI(url))
        data = JSON.parse(response)
      
        # Decode the base64-encoded value
        properties = data['properties'].find { |prop| prop['name'] == 'textures' }
        textures = JSON.parse(Base64.decode64(properties['value']))
      
        # Get the skin URL
        textures['textures']['SKIN']['url']
      end

      def update_minecraft_avatar(user)
        avatar_url = "https://crafatar.com/avatars/#{user.minecraft_uuid}?overlay"
       
        avatar_file = URI.open(avatar_url)
    
        user.avatar.attach(io: avatar_file, filename: "#{user.username}_avatar.png", content_type: 'image/png')
      end


    # Fetch Minecraft UUID from third-party API
    def fetch_minecraft_uuid(username)
      url = "https://api.mojang.com/users/profiles/minecraft/#{username}"
  
      response = HTTParty.get(url)
  
      if response.code == 200
        response.parsed_response['id'] # UUID from API response
      else
        nil
      end
    end
  
    def set_user

      @user = User.find(params[:id])
    end
  end
  