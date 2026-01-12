# app/models/bingo_cell.rb
class BingoCell < ApplicationRecord
  belongs_to :bingo_card
  belongs_to :bingo_item

  # Helper to return coordinate like "B2" or "A0"
  def coordinate
    column_letter = ("A".."Z").to_a[column_index]
    "#{column_letter}#{row_index + 1}"
  end
  
  # Check if this cell contributes to a win
  scope :marked, -> { where(is_marked: true) }
end