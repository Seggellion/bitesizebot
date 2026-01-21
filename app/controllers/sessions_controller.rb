class SessionsController < ApplicationController
  layout 'utility'

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Logged out!'
  end

  def failure
    redirect_to root_path, alert: 'Authentication failed.'
  end

  def create
  auth = request.env['omniauth.auth']
  provider = auth['provider']

  # Step 1: Find or Create the User
  user = User.find_or_create_by(uid: auth['uid'], provider: provider) do |u|
    u.username = auth['info']['name']
    u.first_name = auth['info']['name']
    u.user_type = User.admin_exists? ? 1 : 0 # First user is admin
  end

  # Step 2: Store Twitch-specific data if applicable
  if provider == 'twitch'
      user.update(
        twitch_access_token:  auth.dig('credentials', 'token'),
        twitch_refresh_token: auth.dig('credentials', 'refresh_token'),
        avatar: auth.dig('info', 'image') 
      )
      user.twitch_scopes = auth.dig('credentials', 'scopes')
    elsif provider == 'discord'
      user.update(avatar: auth.dig('info', 'image'))
    end

  # Step 3: Global updates
  user.update(ip_address: request.remote_ip, last_login: Time.current)
  session[:user_id] = user.id

  # Redirect
  path = user.admin? ? admin_root_path : root_path
  redirect_to path, notice: "Signed in via #{provider.titleize}!"
end

# app/models/user.rb
def ensure_token
  # 1. If we don't have a token at all, return nil
  return nil if twitch_access_token.blank?

  # 2. Check if the token is still valid with Twitch
  # We use a memoized variable so we don't ping Twitch 100 times a second
  return @validated_token if @validated_token

  response = HTTParty.get("https://id.twitch.tv/oauth2/validate", headers: {
    "Authorization" => "OAuth #{twitch_access_token}"
  })

  if response.code == 200
    @validated_token = twitch_access_token
  else
    # 3. If invalid (401), use the refresh token to get a new one
    puts "[OAuth] Token expired for #{username}. Refreshing..."
    @validated_token = TwitchService.refresh_token_for(self)
  end
end


  private

  def fetch_minecraft_uuid(access_token)
    # Fetch Xbox Live Token
    xbl_token = get_xbl_token(access_token)

    return nil unless xbl_token

    # Fetch XSTS Token
    
    xsts_token = get_xsts_token(xbl_token)
    return nil unless xsts_token

    # Fetch Minecraft Profile
    get_minecraft_profile(xsts_token)
  end

  def get_xbl_token(access_token)
    url = 'https://user.auth.xboxlive.com/user/authenticate'
    # Rename 'response' to 'api_response'
    api_response = HTTParty.post(url, {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        Properties: {
          AuthMethod: 'RPS',
          SiteName: 'user.auth.xboxlive.com',
          RpsTicket: "d=#{access_token}"
        },
        RelyingParty: 'http://auth.xboxlive.com',
        TokenType: 'JWT'
      }.to_json
    })

    # Optional: check status or log
    return nil unless api_response.code == 200

    # Now safely call parsed_response on the HTTParty response
    api_response.parsed_response.dig('Token')
  end

  def get_xsts_token(xbl_token)
    url = 'https://xsts.auth.xboxlive.com/xsts/authorize'

    api_response = HTTParty.post(url, {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        Properties: {
          SandboxId: 'RETAIL',
          UserTokens: [xbl_token]
        },
        RelyingParty: 'rp://api.minecraftservices.com/',
        TokenType: 'JWT'
      }.to_json
    })

    return nil unless api_response.code == 200
    api_response.parsed_response.dig('Token')
  end

  def get_minecraft_profile(xsts_token)
    url = 'https://api.minecraftservices.com/minecraft/profile'

    api_response = HTTParty.get(url, {
      headers: { 'Authorization' => "Bearer #{xsts_token}" }
    })

    return nil unless api_response.code == 200

    profile = api_response.parsed_response
    profile['id'] # This is the Minecraft UUID
  end
end
