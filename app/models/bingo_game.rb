class BingoGame < ApplicationRecord
  belongs_to :host, class_name: 'User'
  after_initialize :set_default_status, if: :new_record?

  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_items, through: :bingo_game_items
  has_many :mark_memories, class_name: "BingoGameMarkMemory", dependent: :delete_all
  has_many :bingo_cards, dependent: :destroy
  has_many :pending_actions_assoc, through: :bingo_cards, source: :pending_actions
  has_many :bingo_cells, through: :bingo_cards
  
  validates :title, presence: true
  belongs_to :winner, class_name: "User", optional: true

  # --- Callbacks ---
  after_create_commit :broadcast_overlay_refresh
  after_update_commit :broadcast_game_end, if: :saved_change_to_status?
  after_update_commit :broadcast_potential_win_cleanup, if: :saved_change_to_winner_id?
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :cleanup_pending_actions, if: :game_ended?

  # --- Scopes ---
  scope :joinable, -> { where(status: 'invite') }
  scope :active, -> { where(status: 'active') }

  # --- Public Methods (Accessible by Controllers/Workers) ---

  def self.current_or_latest
    active.first || order(created_at: :desc).first
  end

def broadcast_overlay_refresh
  # Use a global string instead of self/id
  broadcast_append_to(
    "active_game_overlay", 
    target: "overlay_notifications",
    partial: "admin/bingo_games/game_ended_signal"
  )
end

  def broadcast_game_end
    if status == 'ended'
      # Tell all card-holders to refresh
      bingo_cards.each { |card| broadcast_refresh_to card }
      
      # Trigger the overlay refresh
      broadcast_overlay_refresh
    end
  end

  def broadcast_status_change
    if status == 'active'
      bingo_cards.each do |card|
        broadcast_replace_to(
          card,
          target: "bingo_card_container",
          partial: "Hobbit/views/pages/card_layout", 
          locals: { card: card, game: self }
        )
      end
    elsif status == 'ended'
      bingo_cards.each { |card| broadcast_refresh_to card }
    end
  end

  def broadcast_potential_win_cleanup
    broadcast_replace_to "potential_winners_#{id}",
                         target: "potential_winners_list",
                         partial: "admin/bingo_games/potential_winners",
                         locals: { bingo_game: self }
  end

  def invite?
    status == 'invite'
  end

  def active?
    status == 'active'
  end

  def game_ended?
    saved_change_to_status? && status == "ended"
  end

  def coordinate_auto_approved?(coord)
    mark_memories.exists?(coordinate: coord)
  end

  def remember_coordinate!(coord, approved_by: nil)
    mark_memories.find_or_create_by!(coordinate: coord) do |rec|
      rec.approved_by = approved_by
    end
  end

  def item_claimed?(bingo_item_id)
    mark_memories.exists?(bingo_item_id: bingo_item_id)
  end

  def claim_item!(bingo_item, approved_by: nil, coordinate: nil)
    attempts = 0
    memory = nil

    begin
      transaction do
        memory_coordinate = coordinate || "#{bingo_item.column_letter}#{bingo_item.row_number}"
        memory = mark_memories.find_by(bingo_item_id: bingo_item.id) ||
                 mark_memories.find_by(coordinate: memory_coordinate, bingo_item_id: nil)

        unless memory
          stored_coordinate = if mark_memories.exists?(coordinate: memory_coordinate)
                                "#{memory_coordinate}:item-#{bingo_item.id}"
                              else
                                memory_coordinate
                              end
          memory = mark_memories.build(coordinate: stored_coordinate)
        end

        memory.bingo_item ||= bingo_item
        memory.approved_by ||= approved_by
        memory.save!

        matching_cells = bingo_cells.where(bingo_item_id: bingo_item.id)
        matching_cell_ids = matching_cells.select(:id)

        matching_cells.where(is_marked: false).find_each do |cell|
          cell.update!(is_marked: true)
        end

        PendingAction.pending
                     .where(action_type: "mark_cell", target_type: "BingoCell", target_id: matching_cell_ids)
                     .find_each { |action| action.update!(status: "approved") }

        memory
      end
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts < 2

      raise
    rescue ActiveRecord::RecordInvalid => error
      retryable_memory_conflict = error.record == memory &&
                                  (memory.errors.of_kind?(:bingo_item_id, :taken) ||
                                   memory.errors.of_kind?(:coordinate, :taken))
      attempts += 1
      retry if retryable_memory_conflict && attempts < 2

      raise
    end
  end

  def pending_actions
    PendingAction.where(target: self).or(PendingAction.where(target: bingo_cells))
  end

  def cleanup_pending_actions
    PendingAction.where(action_type: %w[mark_cell claim_win])
                 .where(target_type: "BingoCell", target_id: bingo_cells.select(:id))
                 .or(PendingAction.where(action_type: %w[mark_cell claim_win],
                                       target_type: "BingoCard", 
                                       target_id: bingo_cards.select(:id)))
                 .delete_all
  end

  private

  def set_default_status  
    self.status ||= 'invite'
  end
end
