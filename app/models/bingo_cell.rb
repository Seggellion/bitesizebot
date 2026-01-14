# app/models/bingo_cell.rb
class BingoCell < ApplicationRecord
  belongs_to :bingo_card
  belongs_to :bingo_item
  

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
  

  # Check if this cell contributes to a win
  scope :marked, -> { where(is_marked: true) }
  
end