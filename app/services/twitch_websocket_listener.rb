
class TwitchWebsocketListener
  @current_ws = nil
  @keepalive_timer = nil

  def self.run(url = 'wss://eventsub.wss.twitch.tv/ws')
    EM.run do
      connect(url)
    end
  end


  
    def self.is_follower?(broadcaster_id, user_id)
  # Broadcaster is always a 'follower' of their own channel
  
  return true if broadcaster_id == user_id

bot_user = User.bot.first
return false unless bot_user


token = user.twitch_access_token
  client_id = Rails.application.credentials.dig(:twitch, :client_id)

  # Twitch API: Check if user follows broadcaster
  # Endpoint: GET https://api.twitch.tv/helix/channels/followers?broadcaster_id=X&user_id=Y
  url = "https://api.twitch.tv/helix/channels/followers?broadcaster_id=#{broadcaster_id}&user_id=#{user_id}"
  
  response = HTTParty.get(url, headers: {
    "Authorization" => "Bearer #{token}",
    "Client-Id" => client_id
  })

  # If the "total" field in the response is 1, they are following.
  if response.code == 200
return response.dig("data").present?
  elsif response.code == 401
    # Handle token refresh if necessary, similar to your get_user_id method
    new_token = TwitchService.refresh_token_for(user)
    # Retry once
    retry_res = HTTParty.get(url, headers: {
      "Authorization" => "Bearer #{new_token}",
      "Client-Id" => client_id
    })
    return retry_res.dig("total").to_i > 0 if retry_res.code == 200
  end

  false
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
    bid = User.broadcaster.uid
    bot = User.bot.first
    sid = bot&.uid # The Bot's numerical ID

    if bid.nil? || sid.nil?
      puts "[Twitch WS] ABORTING: Could not find IDs. (Broadcaster: #{bid.inspect}, Bot: #{sid.inspect})"
      return
    end

    # user = User.where(provider: 'twitch').where.not(twitch_access_token: nil).first
    token = bot.twitch_access_token
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
  user = User.bot
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
  
  unless SystemSetting.bot_enabled?
    return 
  end
  username = event["chatter_user_login"]
  display_name = event["chatter_user_name"]
  text     = event["message"]["text"].downcase.strip
  bid      = event["broadcaster_user_id"]
  uid      = event["chatter_user_id"]
  is_mod   = event["badges"]&.any? { |b| b["set_id"] == "moderator" || b["set_id"] == "broadcaster" }

  # The bot user's ID for sending messages
  user = User.where(provider: 'twitch').where.not(twitch_access_token: nil).first
  sid  = user.uid

  unless is_mod || is_follower?(bid, uid)
    rejection_messages = [
      "Alas, @#{username}, only friends of the Shire may use these tools. Follow the path (hit follow) to enter!",
      "I’m sorry, @#{username}, but you haven't been invited to the tea party yet. Follow the channel to join the Fellowship!",
      "Be gone, foul Orc! Or just follow the channel to prove you're a true Hobbit of the Shire."
    ]
    TwitchService.send_chat_message(bid, sid, rejection_messages.sample)
    return 
  end

  viewer = User.find_or_create_by(uid: uid, provider: 'twitch') do |u|
    u.first_name = display_name
    u.username = display_name
    u.user_type = 1
    u.fame = 0 
  end

  viewer.increment!(:fame, 1)
  viewer.touch

  # 1. HARDCODED COMMANDS (Static Logic)
  case text
  when "!ping"
    TwitchService.send_chat_message(bid, sid, "Pong! @#{username}")
    return

  when /^!(addcmd|delcmd)/
    if is_mod
      response = CommandService.process_command(text, is_mod, display_name)
      TwitchService.send_chat_message(bid, sid, response)
      return
    end

  when /^!raffle/
    response = RaffleService.process_command(uid, username, bid, text, is_mod)
    TwitchService.send_chat_message(bid, sid, response) if response
    return

  when /^!gamble/
    response = GambleService.process_command(viewer, text)
    TwitchService.send_chat_message(bid, sid, "@#{username} #{response}")
    return

  when "!fellowship", /^!lembas/
    response_message = GiveawayService.process_command(uid, username, bid, text)
    TwitchService.send_chat_message(bid, sid, "@#{username}: #{response_message}") if response_message
    return

  when /^!coffer/
    response = CofferService.process_command(uid, username, text, is_mod)
    TwitchService.send_chat_message(bid, sid, "@#{username}: #{response}")
    return

  when /^!bingo/
    if (text == "!bingo start" || text == "!bingo end") && uid != bid
      TwitchService.send_chat_message(bid, sid, "@#{username}: Only the host can use that command!")
      return
    end

    response_message = BingoService.process_command(uid, username, bid, text)
    TwitchService.send_chat_message(bid, sid, "@#{username}: #{response_message}") if response_message
    return
  end

  # 2. DYNAMIC DATABASE COMMANDS (Lookup)
  if text.start_with?("!")
    command_name = text.delete_prefix("!").split(" ").first
    custom_cmd = CustomCommand.cached_find(command_name)

    if custom_cmd
      # Permission check
      if custom_cmd.permission_level == 'moderator' && !is_mod
        return 
      end

      # Variable parsing
      final_message = custom_cmd.response.gsub("{user}", "@#{username}")
      TwitchService.send_chat_message(bid, sid, final_message)
    end
  end
end 

end