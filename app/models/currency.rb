class Currency < ApplicationRecord
  has_many :treasury_balances, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :base_value, presence: true, numericality: { greater_than: 0 }

  # quick helper for tiered value comparisons
  def to_copper_value
    base_value
  end
end
