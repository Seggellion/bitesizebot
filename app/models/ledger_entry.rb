class LedgerEntry < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :entry_type, presence: true

  # Custom validation to prevent negative balance
  validate :user_has_sufficient_funds, on: :create

  private

  def user_has_sufficient_funds
    if amount.negative? && (user.wallet + amount) < 0
      errors.add(:amount, "insufficient funds for this activity")
    end
  end
end