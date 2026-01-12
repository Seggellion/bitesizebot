# app/models/bingo_card.rb
class BingoCard < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :user
  has_many :bingo_cells, dependent: :destroy

  # This callback ensures that as soon as !join is triggered and a card is saved,
  # the 5x5 (or 3x3) grid is populated with items.
  after_create :generate_cells

  private

  def generate_cells
    # 1. Get the items available for this game
    # 2. Randomize them
    # 3. Take exactly enough to fill the grid (e.g., 25 for a 5x5)
    available_items = bingo_game.bingo_items.pluck(:id).shuffle
    grid_size = bingo_game.size

    if available_items.size < (grid_size * grid_size)
      # Fallback logic if host didn't provide enough phrases
      # You might want to raise an error or handle this in the UI validation
    end

    cell_attributes = []
    index = 0

    (0...grid_size).each do |row|
      (0...grid_size).each do |col|
        cell_attributes << {
          bingo_card_id: id,
          bingo_item_id: available_items[index],
          row_index: row,
          column_index: col,
          is_marked: false,
          created_at: Time.current,
          updated_at: Time.current
        }
        index += 1
      end
    end

    # Using insert_all for performance, especially with many Twitch viewers
    BingoCell.insert_all(cell_attributes) if cell_attributes.any?
  end
end