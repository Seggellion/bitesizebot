# app/models/investment.rb
class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :ticker
  # Change this line:
enum :status, { active: 0, redeemed: 1, pending_sale: 2, pending_purchase: 3 }

after_commit :broadcast_user_wallet_update

def current_value
    return amount if redeemed?
    return 0 if purchase_price.to_f <= 0 # Guard for pending_purchase
    
    # Use ticker.current_price directly since we have the association
    # This is safer than Ticker.price_for(name)
    shares = amount.to_f / purchase_price.to_f
    (shares * ticker.current_price).to_i
  end
def pl_dollars
    current_value - amount
  end

def total_profit
    exit_value - amount.to_f
  end

def exit_value

    return 0 if purchase_price.to_f <= 0
    
    shares = amount.to_f / purchase_price.to_f
    (shares * ticker.current_price).round(2)
  end

  def pl_percent
    return 0 if amount <= 0
    (pl_dollars.to_f / amount.to_f) * 100
  end
  

  private
  def broadcast_user_wallet_update
    # We broadcast to the specific user's stream
    # using the wallet data currently stored in their record.
    broadcast_replace_to user,
                         target: "user_wallet_balance",
                         html: "<span class='animate-wallet-update text-sm font-mono text-green-400'>ƒ #{ActionController::Base.helpers.number_with_delimiter(user.reload.wallet)}</span>"
  end


  
end