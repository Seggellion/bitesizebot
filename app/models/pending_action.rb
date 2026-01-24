class PendingAction < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  scope :pending, -> { where(status: 'pending') }
  # Use one consolidated hook for creation
  after_create_commit :handle_new_action
  
  # Use one consolidated hook for updates
  after_update_commit :handle_action_update

def request_coordinate
    # This regex pulls the value "N39" out of "{:coordinate=>\"N39\"}"
    metadata.to_s[/coordinate=>"([^"]+)"/, 1]
  end

  def approve!
    update!(status: 'approved')
    
    transaction do
      case action_type
      when 'mark_cell'        
        target.update!(is_marked: true)
        broadcast_overlay_notification
      when 'claim_win'
        # target is the BingoCard
        game = target.bingo_game
        game.update!(
            status: 'ended', 
            winner: user, 
            ended_at: Time.current
        )
        user.increment!(:karma, 100)
        user.increment!(:fame, 100)

        add_to_monthly_giveaway
        announce_win_to_twitch(game)
        broadcast_overlay_win
      end

    end
  end

  def deny!
    transaction do
    penalty = (action_type == 'claim_win' ? 100 : 10)
        user.decrement!(:karma, penalty)
        update!(status: 'denied')
    end
  end


  private

  def handle_new_action
    # 1. Update the Admin Dashboard
    broadcast_prepend_to "pending_actions", 
                         target: "pending_actions_table_body", 
                         partial: "admin/pending_actions/pending_action", 
                         locals: { action: self }

    # 2. Update the Player's Card
    refresh_target_cell
  end

  def add_to_monthly_giveaway
    giveaway = Giveaway.bingo.open.order(created_at: :desc).first
    
    if giveaway
      entry = giveaway.giveaway_entries.find_or_create_by!(user: user)
      # For Bingo giveaways, usually 1 win = 1 ticket/entry
      entry.increment!(:tickets_count, 1)
      
      # Optional: Log a ledger entry so there's a paper trail for the free entry
      user.ledger_entries.create!(
        amount: 0, 
        entry_type: 'bingo_giveaway_entry',
        metadata: { giveaway_id: giveaway.id, bingo_game_id: target.bingo_game_id }
      )
  end
end

  def handle_action_update
    # 1. Remove from Admin Dashboard
    broadcast_remove_to "pending_actions"

    # 2. Update the Player's Card (clears the spinner)
    refresh_target_cell
  end


  def broadcast_overlay_notification
  return unless action_type == 'mark_cell' && target.is_a?(BingoCell)
  
  game = target.bingo_game
  broadcast_prepend_to(
    "game_overlay_#{game.id}",
    target: "overlay_notifications",
    partial: "admin/bingo_games/notification",
    locals: { user: user, cell: target }
  )

  broadcast_update_to(
    "game_overlay_#{game.id}",
    target: "ticker_container",
    partial: "admin/bingo_games/ticker",
    locals: { game: game }
  )
end

def broadcast_overlay_win
  # For 'claim_win', target is the BingoCard
  game = target.bingo_game
  
  broadcast_prepend_to(
    "game_overlay_#{game.id}",
    target: "overlay_notifications",
    partial: "admin/bingo_games/win_notification",
    locals: { user: user, game: game }
  )
end

  def announce_win_to_twitch(game)
  bot_user = User.bot_user
  return unless bot_user
  
  # 2. Prepare the victory message
  message = "🏆 BINGO! @#{user.username} has just won the game! 🏆 Congrats!"
  
  # 3. Send via TwitchService
  # broadcaster_id is the host's Twitch UID
  # sender_id is the bot's Twitch UID
  TwitchService.send_chat_message(
    game.host.uid, 
    bot_user.uid, 
    message
  )
rescue => e
  Rails.logger.error "[Twitch Announcement Error] #{e.message}"
end

  def refresh_target_cell
    if target.is_a?(BingoCell)
      target.broadcast_refresh 
    elsif target.is_a?(BingoCard)
      # Explicitly point to the Hobbit theme folder path
      broadcast_replace_to target, 
                          target: "bingo_card_container",
                          partial: "Hobbit/views/pages/card_layout", 
                          locals: { card: target, game: target.bingo_game }
    end
  end

end