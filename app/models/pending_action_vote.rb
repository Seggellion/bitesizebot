class PendingActionVote < ApplicationRecord
  belongs_to :pending_action
  belongs_to :moderator, class_name: "User"

  validates :moderator_id, uniqueness: { scope: :pending_action_id }
end
