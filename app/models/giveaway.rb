class Giveaway < ApplicationRecord
  enum :giveaway_type, { ticket: 0, bingo: 1 }
  enum :status, { open: 0, closed: 1, completed: 2 }

  belongs_to :winner, class_name: 'User', optional: true
  has_many :giveaway_entries, dependent: :destroy
  has_many :users, through: :giveaway_entries

  validates :title, presence: true

  def total_tickets
    giveaway_entries.sum(:tickets_count)
  end

  # --- NEW METHODS START ---

  # Helper to get the specific winning entry object based on the winner_id
  def winner_entry
    return nil unless winner_id
    giveaway_entries.find_by(user_id: winner_id)
  end

  # Helper to calculate win percentage for the dashboard
  def win_probability(user)
    return 0.0 unless user
    
    # Find the specific entry for this user
    entry = giveaway_entries.find_by(user: user)
    
    # Guard against division by zero or missing entry
    return 0.0 unless entry && total_tickets.positive?

    (entry.tickets_count.to_f / total_tickets) * 100.0
  end

  # --- NEW METHODS END ---

  def draw_winner!
    # Guard clause: stop if already completed (unless we manually reset it first)
    return if completed? || giveaway_entries.none?

    # 1. Start with all entries
    candidates = giveaway_entries.joins(:user)

    # 2. Secretly filter out Banned Tags & Recent Winners
    banned_user_ids = Tagging.joins(:tag)
                           .where(taggable_type: 'User', tags: { name: 'giveaway_banned' })
                           .select(:taggable_id)
                           
    recent_winner_ids = User.recent_winners(6.months)
                           .where.not(giveaways: { id: self.id })
                           .select(:id)

    eligible_entries = candidates.where.not(user_id: banned_user_ids)
                                 .where.not(user_id: recent_winner_ids)

    # 3. Filter by visible requirements (Karma/Fame)
    eligible_entries = eligible_entries.where("users.karma >= ?", min_karma)
                                     .where("users.fame >= ?", min_fame)

    return nil if eligible_entries.empty?

    # 4. Weighted random draw
    pool = []
    eligible_entries.each do |entry|
      entry.tickets_count.times { pool << entry.user_id }
    end

    self.winner_id = pool.sample
    self.status = :completed
    self.drawn_at = Time.current
    save!
    announce_winner_to_twitch
    winner
  end

private

def announce_winner_to_twitch
  # We need the Broadcaster (channel) and the Bot (sender)
  broadcaster = User.broadcaster
  bot = User.bot_user
  
  return unless broadcaster && bot && winner

  message = "PROCLAMATION: The Horn of Helm Hammerhand shall sound in the Shire! " \
            "Congratulations @#{winner.username}, you have won '#{title}'! 🏆"

  # Call your existing TwitchService
  TwitchService.send_chat_message(broadcaster.uid, bot.uid, message)
rescue => e
  Rails.logger.error "Failed to announce winner: #{e.message}"
end

end