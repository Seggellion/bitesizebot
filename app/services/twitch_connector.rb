class TwitchConnector
  def self.start
    client = Twitch::Chat::Client.new(
      nickname: ENV['TWITCH_BOT_NAME'],
      password: ENV['TWITCH_OAUTH_TOKEN'], # oauth:xxxx
      channel:  ENV['TWITCH_CHANNEL']
    )

    client.on_message do |message|
      # Hand off to a command processor
      TwitchCommandProcessor.call(message.user, message.message)
    end

    client.run!
  end
end