# app/models/raffle_entry.rb
class RaffleEntry < ApplicationRecord
  belongs_to :raffle
  belongs_to :user

  # Ensure a user can only enter a specific raffle once
  validates :user_id, uniqueness: { scope: :raffle_id, message: "has already entered this raffle" }
  
  # Optional: Validation to enforce the 500 cap at the model level
  validate :raffle_not_full, on: :create

  private

  def raffle_not_full
    if raffle.raffle_entries.count >= raffle.max_participants
      errors.add(:base, "This raffle has reached the maximum number of participants.")
    end
  end
end