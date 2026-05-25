# app/models/bingo_game_mark_memory.rb
class BingoGameMarkMemory < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :approved_by, class_name: 'User', optional: true

  validates :coordinate, presence: true
  validates :coordinate, uniqueness: { scope: :bingo_game_id }

  # Trigger the global cascade as soon as a memory is saved
  after_create_commit :auto_update_game_cells!

  private

  def auto_update_game_cells!
    # 1. Find every cell in this specific game that shares this coordinate
    cells = BingoCell.joins(:bingo_card)
                     .where(bingo_cards: { bingo_game_id: bingo_game_id })
                     .where(coordinate: coordinate)

    cells.find_each do |cell|
      # 2. Mark the cell (unless it was the one the admin just manually marked)
      cell.update!(is_marked: true) unless cell.is_marked?

      # 3. Handle players who were already waiting in the Admin queue
      pending = PendingAction.find_by(target: cell, status: 'pending')

      if pending
        # This triggers your existing handle_action_update hook! 
        # It instantly removes the row from the Admin dashboard and refreshes the cell.
        pending.update!(status: 'approved')
      else
        # 4. Handle players who NEVER clicked the cell.
        # Push the updated cell directly to their screen so they see it happen live.
        Turbo::StreamsChannel.broadcast_replace_to(
          cell.bingo_card,
          target: ActionView::RecordIdentifier.dom_id(cell),
          partial: "Hobbit/views/pages/cell", # Ensure this matches your theme's exact path
          locals: { cell: cell }
        )


        Turbo::StreamsChannel.broadcast_replace_to(
          cell.bingo_card, 
          target: "admin_#{ActionView::RecordIdentifier.dom_id(cell)}",
          partial: "admin/bingo_cards/cell", # Ensure this matches your admin partial path
          locals: { cell: cell }
        )

      end
    end
  end
end