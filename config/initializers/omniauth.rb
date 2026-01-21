# config/initializers/omniauth.rb

OmniAuth.config.allowed_request_methods = [:post]

Rails.application.config.middleware.use OmniAuth::Builder do
  if (twitch_creds = Rails.application.credentials.twitch)
    provider :twitch,
      twitch_creds[:client_id],
      twitch_creds[:client_secret]
  end

  if (discord_creds = Rails.application.credentials.discord)
    provider :discord,
      discord_creds[:client_id],
      discord_creds[:client_secret],
      scope: "identify"
  end
end
