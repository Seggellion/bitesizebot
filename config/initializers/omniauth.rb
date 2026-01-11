# config/initializers/omniauth.rb

return unless defined?(OmniAuth)

Rails.application.config.middleware.use OmniAuth::Builder do
  creds = Rails.application.credentials.omniauth

  if creds&.discord
    provider :discord,
      creds.discord.client_id,
      creds.discord.client_secret,
      scope: "identify email"
  end

  if creds&.twitch
    provider :twitch,
      creds.twitch.client_id,
      creds.twitch.client_secret,
      scope: "user:read:email"
  end
end
