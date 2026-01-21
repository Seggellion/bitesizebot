# app/services/twitch_service.rb
class TwitchService
  TWITCH_OAUTH_VALIDATE_URL = "https://id.twitch.tv/oauth2/validate"
  TWITCH_OAUTH_TOKEN_URL    = "https://id.twitch.tv/oauth2/token"

  # --- Public: the rest of the app (including TwitchWebsocketListener) may call these ---

  def self.valid_user_token_for(user)
    return nil unless user&.twitch_access_token.present?

    # Fast path: token still valid
    return user.twitch_access_token if token_valid?(user.twitch_access_token)

    # Slow path: refresh and return the new token (or nil)
    refresh_token_for(user)
  end

  def self.send_chat_message(broadcaster_id, sender_id, message_text)
    bot_user = User.bot_user
    token = valid_user_token_for(bot_user)
    return unless token

    response = post_message(broadcaster_id, sender_id, message_text, token)

    # If Twitch invalidates token between validate and call, refresh once and retry
    if response.code == 401
      new_token = refresh_token_for(bot_user)
      response = post_message(broadcaster_id, sender_id, message_text, new_token) if new_token
    end

    puts "[Twitch API] Error sending message: #{response.body}" if response && response.code != 200
    response
  end

  # IMPORTANT: now PUBLIC (so TwitchWebsocketListener can call it safely)
  def self.refresh_token_for(user)
    return nil unless user&.twitch_refresh_token.present?

    response = HTTParty.post(
      TWITCH_OAUTH_TOKEN_URL,
      body: {
        grant_type:    "refresh_token",
        refresh_token: user.twitch_refresh_token,
        client_id:     Rails.application.credentials.dig(:twitch, :client_id),
        client_secret: Rails.application.credentials.dig(:twitch, :client_secret)
      }
    )

    unless response.code == 200
      puts "[Twitch API] Failed to refresh token: #{response.code} - #{response.body}"
      return nil
    end

    data = response.parsed_response

    # Twitch may rotate refresh tokens; only overwrite if present
    updates = { twitch_access_token: data["access_token"] }
    updates[:twitch_refresh_token] = data["refresh_token"] if data["refresh_token"].present?

    user.update(updates)
    puts "[Twitch API] Token refreshed successfully for #{user.username}."
    data["access_token"]
  end

  # --- Private helpers ---

  def self.token_valid?(access_token)
    res = HTTParty.get(
      TWITCH_OAUTH_VALIDATE_URL,
      headers: { "Authorization" => "OAuth #{access_token}" }
    )
    res.code == 200
  end
  private_class_method :token_valid?

  def self.post_message(broadcaster_id, sender_id, message_text, token)
    url = "https://api.twitch.tv/helix/chat/messages"
    headers = {
      "Authorization" => "Bearer #{token}",
      "Client-Id"     => Rails.application.credentials.dig(:twitch, :client_id),
      "Content-Type"  => "application/json"
    }
    body = {
      broadcaster_id: broadcaster_id.to_s,
      sender_id:      sender_id.to_s,
      message:        message_text
    }.to_json

    HTTParty.post(url, headers: headers, body: body)
  end
  private_class_method :post_message
end
