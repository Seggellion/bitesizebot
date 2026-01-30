# app/models/investment.rb
class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :ticker
  # Change this line:
  enum :status, { active: 0, redeemed: 1 }

def current_value
    return amount if redeemed?
    
    market_price = Ticker.price_for(investment_name)
    # Calculation: (Money Invested / Price at Purchase) * Current Price
    # This automatically handles gains and losses.
    ((amount.to_f / purchase_price) * market_price).to_i
  end

  def profit
    current_value - amount
  end
  
end