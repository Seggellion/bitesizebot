class PendingAction < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  scope :pending, -> { where(status: 'pending') }

  # Use one consolidated hook for creation
  after_create_commit :handle_new_action
  
  # Use one consolidated hook for updates
  after_update_commit :handle_action_update

def approve!
    
    transaction do
      case action_type
      when 'mark_cell'        
        target.update!(is_marked: true)
      end
      update!(status: 'approved')
    end
  end

  def deny!
    transaction do
      user.decrement!(:karma, 10)
      update!(status: 'denied')
    end
  end


  private

  def handle_new_action
    # 1. Update the Admin Dashboard
    broadcast_prepend_to "pending_actions", 
                         target: "pending_actions_table_body", 
                         partial: "admin/pending_actions/pending_action", 
                         locals: { action: self }

    # 2. Update the Player's Card
    refresh_target_cell
  end

  def handle_action_update
    # 1. Remove from Admin Dashboard
    broadcast_remove_to "pending_actions"

    # 2. Update the Player's Card (clears the spinner)
    refresh_target_cell
  end

  def refresh_target_cell
    # If byebug still doesn't hit here, the transaction is not committing!
    if target.is_a?(BingoCell)
      target.broadcast_refresh 
    end
  end
end