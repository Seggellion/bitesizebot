# config/initializers/omniauth.rb

OmniAuth.config.allowed_request_methods = [:post]

Rails.application.config.middleware.use OmniAuth::Builder do
  # Direct access to the top-level 'twitch' key
  if (twitch_creds = Rails.application.credentials.twitch)
    provider :twitch,
      twitch_creds[:client_id],
      twitch_creds[:client_secret],
      scope: "user:read:email user:read:chat user:write:chat user:bot channel:bot moderator:read:followers"
  end

  # Adjust discord if it is also top-level in your credentials
  if (discord_creds = Rails.application.credentials.discord)
    provider :discord,
      discord_creds[:client_id],
      discord_creds[:client_secret],
      scope: "identify email"
  end
end