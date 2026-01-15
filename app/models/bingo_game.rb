class BingoGame < ApplicationRecord
  belongs_to :host, class_name: 'User'
  
  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_items, through: :bingo_game_items
  
  has_many :bingo_cards, dependent: :destroy
  
  validates :title, presence: true
  belongs_to :winner, class_name: "User", optional: true

  after_update_commit :broadcast_game_end, if: :saved_change_to_status?

after_update_commit :broadcast_potential_win_cleanup, if: :saved_change_to_winner_id?

def self.active
  self.where(status:"active")
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
end