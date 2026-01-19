# app/services/twitch_service.rb
class TwitchService
  def self.send_chat_message(broadcaster_id, sender_id, message_text)
    bot_user = User.bot_user
    return unless bot_user&.twitch_access_token

    response = post_message(broadcaster_id, sender_id, message_text, bot_user.twitch_access_token)

    # If token is expired (401), refresh it and try one more time
    if response.code == 401
      puts "[Twitch API] Token expired for #{bot_user.username}. Refreshing..."
      new_token = refresh_token_for(bot_user)
      
      if new_token
        response = post_message(broadcaster_id, sender_id, message_text, new_token)
      end
    end

    puts "[Twitch API] Error sending message: #{response.body}" if response.code != 200
    response
  end

  private

  def self.post_message(broadcaster_id, sender_id, message_text, token)
    url = "https://api.twitch.tv/helix/chat/messages"
    headers = {
      "Authorization" => "Bearer #{token}",
      "Client-Id"     => Rails.application.credentials.twitch[:client_id],
      "Content-Type"  => "application/json"
    }
    body = {
      broadcaster_id: broadcaster_id.to_s,
      sender_id:      sender_id.to_s,
      message:        message_text
    }.to_json

    HTTParty.post(url, headers: headers, body: body)
  end

  def self.refresh_token_for(user)
    return nil unless user.twitch_refresh_token

    url = "https://id.twitch.tv/oauth2/token"
    response = HTTParty.post(url, body: {
      grant_type: 'refresh_token',
      refresh_token: user.twitch_refresh_token,
      client_id: Rails.application.credentials.twitch[:client_id],
      client_secret: Rails.application.credentials.twitch[:client_secret]
    })

    if response.code == 200
      data = response.parsed_response
      user.update(
        twitch_access_token: data['access_token'],
        twitch_refresh_token: data['refresh_token']
      )
      puts "[Twitch API] Token refreshed successfully."
      data['access_token']
    else
      puts "[Twitch API] Failed to refresh token: #{response.body}"
      nil
    end
  end
end