
class TwitchWebsocketListener
  @current_ws = nil
  @keepalive_timer = nil

  def self.run(url = 'wss://eventsub.wss.twitch.tv/ws')
    EM.run do
      connect(url)
    end
  end

  def self.connect(url)
    @current_ws = Faye::WebSocket::Client.new(url)

    @current_ws.on :open do |event|
      puts "[Twitch WS] Connected to #{url}"
    end

    @current_ws.on :message do |event|
      data = JSON.parse(event.data)
      reset_keepalive_timer(data)
      
      handle_message(data)
    end

    @current_ws.on :close do |event|
      puts "[Twitch WS] Closed: #{event.code} #{event.reason}. Retrying..."
      # If it wasn't a clean Twitch-initiated reconnect, wait and retry
      EM.add_timer(5) { run } unless event.code == 4004 # Graceful reconnect code
    end
  end

  def self.handle_message(data)
    metadata = data["metadata"]
    payload  = data["payload"]

    case metadata["message_type"]
    when "session_welcome"
      session_id = payload["session"]["id"]
      puts "[Twitch WS] Welcome! Session ID: #{session_id}"
      
      # If this is a fresh connection (not a reconnect), we must subscribe
      # Reconnects automatically carry over subscriptions
      subscribe_to_chat(session_id) if payload["session"]["reconnect_url"].nil?

    when "session_reconnect"
      reconnect_url = payload["session"]["reconnect_url"]
      puts "[Twitch WS] Reconnecting to #{reconnect_url}..."
      # Twitch gives us 30 seconds to connect to the new URL
      connect(reconnect_url)

    when "session_keepalive"
      # Just resets our local timer to ensure connection hasn't ghosted
      puts "[Twitch WS] Keepalive received"

    when "notification"
      handle_notification(payload["event"])
    end
  end

  def self.reset_keepalive_timer(data)
    # Twitch sends a Keepalive every ~10s. If we hear nothing for 15s, the socket is dead.
    timeout = data.dig("payload", "session", "keepalive_timeout_seconds") || 15
    
    @keepalive_timer&.cancel
    @keepalive_timer = EM::Timer.new(timeout + 2) do
      puts "[Twitch WS] Keepalive missed. Reconnecting..."
      @current_ws.close
      run # Restart the whole loop
    end
  end
def self.subscribe_to_chat(session_id)
    # Fetch IDs and confirm they aren't nil
    bid = get_user_id("seggellion")
    sid = get_user_id(nil) # This gets the ID of the token owner

    if bid.nil? || sid.nil?
      puts "[Twitch WS] ABORTING: Could not find IDs. (Broadcaster: #{bid.inspect}, Bot: #{sid.inspect})"
      return
    end

    user = User.where(provider: 'twitch').where.not(twitch_access_token: nil).first
    token = user.twitch_access_token
    client_id = Rails.application.credentials.dig(:twitch, :client_id)


    response = HTTParty.post("https://api.twitch.tv/helix/eventsub/subscriptions", 
      headers: {
        "Authorization" => "Bearer #{token}",
        "Client-Id"     => client_id,
        "Content-Type"  => "application/json"
      },
      body: {
        type: "channel.chat.message",
        version: "1",
        condition: { 
          broadcaster_user_id: bid.to_s, # Ensure it's a string
          user_id: sid.to_s              # Ensure it's a string
        },
        transport: { method: "websocket", session_id: session_id }
      }.to_json
    )
    
    puts "[Twitch WS] Subscription Result: #{response.code} - #{response.body}"
  end

 def self.get_user_id(login = nil)
  user = User.find_by(first_name: 'Seggellion')
  return nil unless user

  url = login ? "https://api.twitch.tv/helix/users?login=#{login}" : "https://api.twitch.tv/helix/users"
  
  # Try the request
  res = make_id_request(url, user.twitch_access_token)

  # If expired, refresh and try once more
  if res.code == 401
    new_token = TwitchService.refresh_token_for(user) # Reuse the logic from TwitchService
    res = make_id_request(url, new_token) if new_token
  end

  res.dig("data", 0, "id") if res.code == 200
end

def self.make_id_request(url, token)
  HTTParty.get(url, headers: { 
    "Authorization" => "Bearer #{token}", 
    "Client-Id" => Rails.application.credentials.twitch[:client_id] 
  })
end

  def self.handle_notification(event)
    username = event["chatter_user_login"]
    text     = event["message"]["text"]
    bid      = event["broadcaster_user_id"]
    uid = event["chatter_user_id"]

    user = User.where(provider: 'twitch').where.not(twitch_access_token: nil).first
  sid = user.uid
    case text.downcase.strip
    when "!ping"
        puts "  -> Responding to ping..."
      TwitchService.send_chat_message(bid, sid, "Pong! @#{username}")
    when "!bingo join"
        response_message = BingoService.process_command(uid,username, bid, text)
        if response_message
            TwitchService.send_chat_message(bid, sid, "@#{username}: #{response_message}")
        end

      #  TwitchService.send_chat_message(bid, user.uid, "Welcome to the game @#{username}! Your card has been generated.")
    when /^!bingo mark\s+[a-z]\d+/i 
        response_message = BingoService.process_command(uid,username, bid, text)
        
        if response_message
        TwitchService.send_chat_message(bid, sid, "@#{username}: #{response_message}")
        end
    end

  end
end