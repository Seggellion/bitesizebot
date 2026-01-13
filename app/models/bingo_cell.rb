# app/models/bingo_cell.rb
class BingoCell < ApplicationRecord
  belongs_to :bingo_card
  belongs_to :bingo_item

  # Helper to return coordinate like "B2" or "A0"
def coordinate
  # Uses the item's row number (1-75) and column letter (B-O)
  "#{bingo_item.column_letter}#{bingo_item.row_number}"
end
  
  # Check if this cell contributes to a win
  scope :marked, -> { where(is_marked: true) }
end