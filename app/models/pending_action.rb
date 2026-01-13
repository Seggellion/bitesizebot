class PendingAction < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  scope :pending, -> { where(status: 'pending') }

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
end