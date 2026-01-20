# app/services/coffer_service.rb
class CofferService
  def self.process_command(uid, username, text, is_mod = false)
    user = User.find_or_create_by(uid: uid) do |u|
      u.username = username
      u.provider = 'twitch'
      u.user_type = 1
    end

    # pineapple
    is_host =User.broadcaster

    case text.downcase

    when "!market"
      tickers = Ticker.all
      return "The market is currently empty." if tickers.empty?

      ticker_list = tickers.map do |t|
        # Format: altama: 105.4 (▲ 5.4%)
        change = ((t.current_price - 100.0) / 100.0 * 100).round(1)
        direction = change >= 0 ? "▲" : "▼"
        "#{t.name.upcase}: #{t.current_price.round(2)} (#{direction} #{change.abs}%)"
      end.join(" | ")

      "Current Market Prices: #{ticker_list}"

    when "!coffer"
      active_investments = user.investments.active
      if active_investments.any?
        total_value = active_investments.sum(&:current_value)
        "Balance: #{user.wallet} | Portfolio Value: #{total_value} farthings across #{active_investments.count} stocks."
      else
        "Your balance is #{user.wallet} farthings. No active investments."
      end

    when /^!coffer redeem (.+)/
    name = $1.strip
    investment = user.investments.active.find_by("lower(investment_name) = ?", name.downcase)
    
    return "Investment '#{name}' not found." unless investment

    ActiveRecord::Base.transaction do
        final_amount = investment.current_value
        
        # 1. Add the total (principal + interest) back to balance
        CurrencyService.update_balance(
        user: user, 
        amount: final_amount, 
        type: 'investment_redemption', 
        metadata: { name: name, principal: investment.amount, interest: investment.profit }
        )
        
        # 2. Close the investment
        investment.redeemed!
        "Redeemed '#{name}' for #{final_amount} farthings! (Profit: +#{investment.profit})"
    end

    # MULTISEND START

    when /^!coffer multisend -t(\d+)\s+(\d+)/
      return "Access Denied: Only the Host can perform mass grants." unless is_host
      
      minutes = $1.to_i
      amount = $2.to_i
      
      return "Amount must be greater than 0." if amount <= 0
      
      # Logic: Find users updated within the last X minutes
      active_users = User.where("updated_at >= ?", minutes.minutes.ago)
      
      if active_users.any?
        # Using a transaction for database integrity
        ActiveRecord::Base.transaction do
          active_users.find_each do |target_user|
            CurrencyService.update_balance(
              user: target_user,
              amount: amount,
              type: 'mass_grant',
              metadata: { 
                trigger_source: 'twitch_command', 
                triggered_by: username,
                timeframe: minutes 
              }
            )
          end
        end
        "Mass Grant Successful! Sent #{amount} farthings to #{active_users.count} users active in the last #{minutes}m."
      else
        "No users found active in the last #{minutes} minutes."
      end

      # EOL multisend

    when /^!coffer transfer (\d+) (\w+)/
      amount = $1.to_i
      receiver_name = $2.delete('@')
receiver = User.find_by("LOWER(username) = ?", receiver_name.downcase)

      return "User #{receiver_name} not found." unless receiver
      return "You can't transfer to yourself!" if receiver == user

      begin
        CurrencyService.transfer(from_user: user, to_user: receiver, amount: amount)
        "Successfully transferred #{amount} to @#{receiver_name}!"
      rescue CurrencyService::InsufficientFundsError
        "Transaction failed: Insufficient funds."
      end

    when /^!coffer invest (\d+) (.+)/
      amount = $1.to_i
      name = $2.strip
    invest_logic(user, amount, name, is_mod)
    else
      "Unknown coffer command. Use !coffer, !coffer transfer, or !coffer invest."
    end
  end

  private

def self.invest_logic(user, amount, name, is_mod)
  current_market_price = Ticker.price_for(name)

  return "Minimum investment is 10 farthings." if amount < 10

  # We check if this 'Ticker' has ever been traded
  ticker_exists = Ticker.exists?(name: name.downcase)

  if !ticker_exists
    if is_mod
      create_new_investment(user, amount, name, current_market_price)
    else
      "Ticker '#{name}' isn't listed yet. Ask a Moderator to IPO it!"
    end
  else
    buy_into_investment(user, amount, name, current_market_price)
  end
rescue CurrencyService::InsufficientFundsError
  "You don't have enough farthings!"
end

def self.create_new_investment(user, amount, name, price)
  ActiveRecord::Base.transaction do
    # Create the global Ticker entry
    Ticker.create!(name: name.downcase, current_price: price)
    
    CurrencyService.update_balance(user: user, amount: -amount, type: 'stock_purchase')
    Investment.create!(
      user: user, 
      amount: amount, 
      investment_name: name, 
      purchase_price: price # Store the entry price!
    )
  end
  "IPO Alert! '#{name}' listed at #{price} farthings. You bought in with #{amount}!"
end

def self.buy_into_investment(user, amount, name, price)
  ActiveRecord::Base.transaction do
    CurrencyService.update_balance(user: user, amount: -amount, type: 'stock_purchase')
    Investment.create!(
      user: user, 
      amount: amount, 
      investment_name: name, 
      purchase_price: price
    )
  end
  "Bought into '#{name}' at market price #{price.round(2)}!"
end



end