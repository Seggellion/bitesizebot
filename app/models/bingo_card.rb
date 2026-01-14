# app/models/bingo_card.rb
class BingoCard < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :user
  has_many :bingo_cells, dependent: :destroy
has_many :bingo_items, through: :bingo_cells

  # This callback ensures that as soon as !join is triggered and a card is saved,
  # the 5x5 (or 3x3) grid is populated with items.
  after_create :generate_cells

  def self.request_mark(viewer, game, col_letter, row_num)
    card = game.bingo_cards.find_by(user_id: viewer.id)
  coord = "#{col_letter.upcase}#{row_num}"
  
  # Find the cell directly by the human-readable coordinate
  cell = card.bingo_cells.find_by(coordinate: coord)
    return "That's the free space!" if cell&.bingo_item&.content == "FREE"
    
    
    return "Invalid cell coordinate!" unless cell
    return "That cell is already marked!" if cell.is_marked
    # Check if a request is already pending for this specific cell
    if PendingAction.exists?(target: cell, status: 'pending')
      return "A request for #{col_letter}#{row_num} is already awaiting approval!"
    end

    PendingAction.create!(
      user: viewer,
      target: cell,
      action_type: 'mark_cell',
      metadata: { coordinate: "#{col_letter}#{row_num}" }
    )

    "Request sent! An admin will review your mark for #{col_letter}#{row_num}."
  end

  private

# app/models/bingo_card.rb
def generate_cells
  grid_size = bingo_game.size
  center_index = grid_size / 2
  column_map = ["B", "I", "N", "G", "O"].first(grid_size)
  
  # Find our special item
  free_item = BingoItem.find_by(content: "HOBBIT NOT PAYING ATTENTION")
  cell_attributes = []

  column_map.each_with_index do |letter, col_idx|
    # Get random items, excluding the free space phrase
    column_pool = BingoItem.where(column_letter: letter)
                           .where.not(content: "HOBBIT NOT PAYING ATTENTION")
                           .order("RANDOM()")
                           .limit(grid_size)
                           .to_a

    (0...grid_size).each do |row_idx|
      is_center = (col_idx == center_index && row_idx == center_index)

      if is_center
        item = free_item
        coord = "FREE"
        marked = true
      else
        item = column_pool.pop
        coord = "#{letter}#{item.row_number}"
        marked = false
      end

      cell_attributes << {
        bingo_card_id: id,
        bingo_item_id: item.id,
        coordinate: coord,
        is_marked: marked,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end

  BingoCell.insert_all(cell_attributes)
end

end