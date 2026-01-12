# app/services/twitch_command_processor.rb
class TwitchCommandProcessor
  def self.call(username, text)
    return unless text.start_with?('!')

    parts = text.split(' ')
    command = parts[0].downcase # !bingo
    action  = parts[1]&.downcase # join

    if command == '!bingo' && action == 'join'
      handle_bingo_join(username)
    end
  end

  private

  def self.handle_bingo_join(username)
    # Find or create the viewer in your Railpress database
    viewer = Viewer.find_or_create_by(twitch_username: username)
    
    # Logic to add them to the active bingo game
    game = BingoGame.active.first
    
    if game.join(viewer)
      puts "Success: #{username} has joined the game."
      # You could trigger a Twitch chat response here via the client
    else
      puts "Fail: Game is full or already started."
    end
  end
end