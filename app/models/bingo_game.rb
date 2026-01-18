class BingoGame < ApplicationRecord
  belongs_to :host, class_name: 'User'
  
  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_items, through: :bingo_game_items
  
  has_many :bingo_cards, dependent: :destroy
  has_many :pending_actions, through: :bingo_cards, source: :pending_actions
  has_many :bingo_cells, through: :bingo_cards
  validates :title, presence: true
  belongs_to :winner, class_name: "User", optional: true

  after_update_commit :broadcast_game_end, if: :saved_change_to_status?
  after_update_commit :broadcast_potential_win_cleanup, if: :saved_change_to_winner_id?
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

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

  def self.current_or_latest
    active.first || order(created_at: :desc).first
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
    end
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