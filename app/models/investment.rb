# app/models/investment.rb
class Investment < ApplicationRecord
  belongs_to :user
  
  # Change this line:
  enum :status, { active: 0, redeemed: 1 }

  def current_value
    return amount if redeemed?
    
    # Simple growth: 1% per hour
    hours_passed = ((Time.current - created_at) / 1.hour).to_i
    
    # Ensure interest_rate isn't nil to avoid math errors
    rate = interest_rate || 0.01
    (amount + (amount * rate * hours_passed)).to_i
  end

  def profit
    current_value - amount
  end
end