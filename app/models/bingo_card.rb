# app/models/bingo_card.rb
class BingoCard < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :user
  has_many :bingo_cells, dependent: :destroy

  # This callback ensures that as soon as !join is triggered and a card is saved,
  # the 5x5 (or 3x3) grid is populated with items.
  after_create :generate_cells

  private

# app/models/bingo_card.rb
def generate_cells
  grid_size = bingo_game.size
  column_map = ["B", "I", "N", "G", "O"]
  cell_attributes = []

  column_map.first(grid_size).each do |letter|
    # Get items for this column
    column_pool = BingoItem.where(column_letter: letter).pluck(:id, :row_number).shuffle

    (1..grid_size).each do |target_row|
      # Find the item specifically for this row number if your items are fixed,
      # or just pop if items are randomized per column.
      item_id, row_num = column_pool.pop

      cell_attributes << {
        bingo_card_id: id,
        bingo_item_id: item_id,
        coordinate: "#{letter}#{row_num}", # Easy for humans/logs
        is_marked: false,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end

  BingoCell.insert_all(cell_attributes) if cell_attributes.any?
end

end