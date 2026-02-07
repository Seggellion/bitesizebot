class LedgerEntry < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :entry_type, presence: true
TRADING_TYPES = ["stock_purchase_add", "stock_purchase_sell","stock_sell","stock_buy"].freeze
  # Custom validation to prevent negative balance
  validate :user_has_sufficient_funds, on: :create

def display_type
  case entry_type
  when 'stock_buy', 'stock_purchase_add'
    'buy'
  when 'stock_sell', 'stock_purchase_sell'
    'sell'
  else
    entry_type.gsub('stock_', '').gsub('_', ' ')
  end
end

  # Only broadcast if it's a trade
  after_create_commit -> { 
    if TRADING_TYPES.include?(entry_type)
      broadcast_prepend_to "global_ledger", 
                          target: "ledger_entries", 
                          partial: "Hobbit/views/shared/entry", 
                          locals: { entry: self } 
    end
  }

  private

  def user_has_sufficient_funds
    if amount.negative? && (user.wallet + amount) < 0
      errors.add(:amount, "insufficient funds for this activity")
    end
  end
end