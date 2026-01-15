# app/models/bingo_cell.rb
class BingoCell < ApplicationRecord
  belongs_to :bingo_card
  belongs_to :bingo_item
  after_update_commit :broadcast_potential_win, if: :saved_change_to_is_marked?
  has_one :bingo_game, through: :bingo_card
after_update_commit :broadcast_mini_card_update
# This handles the "Approved" state update
  after_update_commit :broadcast_refresh

  def broadcast_refresh
        @active_theme = Setting.get("current-theme") || "Dusk"
    broadcast_replace_to(
      bingo_card,
      target: ActionView::RecordIdentifier.dom_id(self),
    partial: "#{@active_theme}/views/pages/cell",
      locals: { cell: self }
    )
  end
  
  # app/models/bingo_cell.rb
  def pending?
    # Checks if there is an un-resolved action for this specific cell
    PendingAction.where(target: self, status: 'pending').exists?
  end

  # Check if this cell contributes to a win
  scope :marked, -> { where(is_marked: true) }



  private

  def broadcast_mini_card_update
  # This broadcasts to the specific card's mini-view
  broadcast_replace_to "bingo_game_#{bingo_game.id}",
                       target: "mini_card_#{bingo_card.id}",
                       partial: "admin/bingo_games/mini_card",
                       locals: { card: bingo_card }
end

  def broadcast_potential_win
    # We broadcast to a stream unique to the current game
    broadcast_replace_to "potential_winners_#{bingo_game.id}",
                         target: "potential_winners_list",
                         partial: "admin/bingo_games/potential_winners",
                         locals: { bingo_game: bingo_game }
  end

  
end