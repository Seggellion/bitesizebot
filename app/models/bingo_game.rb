class BingoGame < ApplicationRecord
  belongs_to :host, class_name: 'User'
  
  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_items, through: :bingo_game_items
  has_many :mark_memories, class_name: "BingoGameMarkMemory", dependent: :delete_all
  has_many :bingo_cards, dependent: :destroy
  has_many :pending_actions, through: :bingo_cards, source: :pending_actions
  has_many :bingo_cells, through: :bingo_cards
  validates :title, presence: true
  belongs_to :winner, class_name: "User", optional: true

  after_update_commit :broadcast_game_end, if: :saved_change_to_status?
  after_update_commit :broadcast_potential_win_cleanup, if: :saved_change_to_winner_id?
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :cleanup_pending_actions, if: :game_ended?

  scope :joinable, -> { where(status: 'invite') }
  scope :active, -> { where(status: 'active') }

  def self.active
    self.where(status:"active")
  end

  def invite?
    status == 'invite'
  end

  def active?
    status == 'active'
  end

  def game_ended?
  saved_change_to_status? && status == "ended"
end

def cleanup_pending_actions
  cleanup_pending_actions!
end


  def self.current_or_latest
    active.first || order(created_at: :desc).first
  end

  def coordinate_auto_approved?(coord)
    mark_memories.exists?(coordinate: coord)
  end

  def remember_coordinate!(coord, approved_by: nil)
    mark_memories.find_or_create_by!(coordinate: coord) do |rec|
      rec.approved_by = approved_by
    end
  end

  private

def broadcast_potential_win_cleanup
  broadcast_replace_to "potential_winners_#{id}",
                       target: "potential_winners_list",
                       partial: "admin/bingo_games/potential_winners",
                       locals: { bingo_game: self }

end

  def broadcast_game_end
    if status == 'ended'
      # Tell all card-holders to refresh or show the victory banner
      bingo_cards.each do |card|
        broadcast_refresh_to card
      end

      # Overlay refresh signal
      broadcast_append_to(
        "game_overlay_#{id}",
        target: "overlay_notifications",
        partial: "admin/bingo_games/game_ended_signal"
      )

    end
  end

  def cleanup_pending_actions!
    PendingAction
      .where(action_type: %w[mark_cell claim_win])
      .where(
        target_type: "BingoCell",
        target_id: bingo_cells.select(:id)
      )
      .or(
        PendingAction.where(
          action_type: %w[mark_cell claim_win],
          target_type: "BingoCard",
          target_id: bingo_cards.select(:id)
        )
      )
      .delete_all
  end


def broadcast_status_change
    if status == 'active'
      # When the game goes active, we want to hide the replacement UI for everyone
      bingo_cards.each do |card|
        broadcast_replace_to(
          card,
          target: "bingo_card_container",
        partial: "Hobbit/views/pages/card_layout", 
          locals: { card: card, game: self }
        )
      end
    elsif status == 'ended'
      # Keep your existing logic for game end
      bingo_cards.each { |card| broadcast_refresh_to card }
    end
  end

def pending_actions
    PendingAction.where(target: self).or(PendingAction.where(target: bingo_cells))
  end

end