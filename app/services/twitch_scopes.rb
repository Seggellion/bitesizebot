# app/services/twitch_scopes.rb
class TwitchScopes
  LIGHT = %w[
    user:read:chat
  ].freeze

  BOT = %w[
    user:read:chat
    user:write:chat
    user:bot
    channel:bot
    moderator:read:followers
  ].freeze

  def self.for_frontend_login
    if User.bot_user.present? && User.broadcaster.present?
      LIGHT
    else
      BOT
    end
  end
end
