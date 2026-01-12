# app/services/bingo_service.rb
class BingoService
  def self.process_command(username, broadcaster_uid, text)
    # 1. Find the host (the streamer)
    host = User.find_by(uid: broadcaster_uid)
    return unless host

    # 2. Find the active game for this host
    game = BingoGame.where(host: host, status: 'active').first
    
    if game.nil?
      # Optional: Send chat message saying "No active game"
      return
    end

    # 3. Find or create the viewer user
    # Note: Twitch events usually provide 'chatter_user_id'. 
    # If your handle_notification passes the ID, use that for UID.
    viewer = User.find_or_create_by(username: username) do |u|
      u.provider = 'twitch'
      u.uid = "#{u.uid}" # Ideally pass chatter_user_id from the event
    end

    # 4. Check if they already have a card
    if game.bingo_cards.exists?(user: viewer)
      # Optional: Send chat message "You already have a card!"
      return
    end

    # 5. Issue the card (this triggers generate_cells in the model)
    game.bingo_cards.create!(user: viewer)
  end
end