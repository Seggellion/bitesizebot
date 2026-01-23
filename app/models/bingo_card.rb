# app/models/bingo_card.rb
class BingoCard < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :user
  has_many :bingo_cells, dependent: :destroy
has_many :bingo_items, through: :bingo_cells
after_create_commit :broadcast_new_participant
after_create_commit :broadcast_total_stats

accepts_nested_attributes_for :bingo_cells, allow_destroy: false
  # This callback ensures that as soon as !join is triggered and a card is saved,
  # the 5x5 (or 3x3) grid is populated with items.
  after_create :generate_cells

def pending_actions
    # This combines the claim on the card itself and any marks on its cells
    PendingAction.where(target: self)
                 .or(PendingAction.where(target: bingo_cells))
  end

 def replace_card!(cost = 2000)
    transaction do
      # 1. Create the Ledger Entry
      # This will trigger the 'user_has_sufficient_funds' validation in LedgerEntry
      user.ledger_entries.create!(
        amount: -cost,
        entry_type: "bingo_card_replacement",
        metadata: { bingo_game_id: bingo_game_id, bingo_card_id: id }
      )

      # 2. Update the user's wallet column
      # We use lock! to prevent race conditions during the balance update
      user.lock!
      user.decrement!(:wallet, cost)

      # 3. Regenerate the card
      bingo_cells.destroy_all
      generate_cells
      increment!(:replacement_count)

      # 4. Broadcast the update to the UI
      # This replaces the 'bingo_card_container' with the new layout
      broadcast_replace_to(
        self,
        target: "bingo_card_container",
        partial: "Hobbit/views/pages/card_layout", 
        locals: { card: self, game: self.bingo_game }
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    # If the ledger validation fails, the transaction rolls back
    errors.add(:base, "Transaction failed: #{e.record.errors.full_messages.join(', ')}")
    false
  end


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

  def won?
    # A card is won if its user is the winner of the associated game
    bingo_game.winner_id == self.user_id
  end

  def verify_win
    # Fetch all marked cells and their positions in the grid
    # We reconstruct the grid based on the order they were created (id)
    marked_positions = bingo_cells.order(:id).each_with_index.map do |cell, index|
      { 
        marked: cell.is_marked, 
        row: index % 5, 
        col: index / 5 
      }
    end

    # 1. Check Rows
    (0..4).each do |r|
      return true if marked_positions.select { |cp| cp[:row] == r && cp[:marked] }.size == 5
    end

    # 2. Check Columns
    (0..4).each do |c|
      return true if marked_positions.select { |cp| cp[:col] == c && cp[:marked] }.size == 5
    end

    # 3. Check Diagonal (Top-Left to Bottom-Right)
    # Positions: (0,0), (1,1), (2,2), (3,3), (4,4)
    if marked_positions.select { |cp| cp[:row] == cp[:col] && cp[:marked] }.size == 5
      return true
    end

    # 4. Check Anti-Diagonal (Top-Right to Bottom-Left)
    # Positions: (0,4), (1,3), (2,2), (3,1), (4,0)
    if marked_positions.select { |cp| cp[:row] + cp[:col] == 4 && cp[:marked] }.size == 5
      return true
    end

    false
  end



  private

def broadcast_new_participant
  # 1. Add the new user to the list
  broadcast_append_to "participants_game_#{bingo_game_id}",
                      target: "participants_list",
                      partial: "admin/bingo_games/participant",
                      locals: { card: self }

  # 2. Update the counter badge
  broadcast_update_to "participants_game_#{bingo_game_id}",
                      target: "participant_count",
                      html: bingo_game.bingo_cards.count.to_s
end

def broadcast_total_stats
  total_count = User.joins(:bingo_cards).distinct.count
  broadcast_update_to "global_admin_stats", 
                      target: "total_all_time_participants", 
                      html: total_count.to_s
end

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