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

   when "!coffer market"
      tickers = Ticker.all
      return "The market is currently empty." if tickers.empty?

      ticker_list = tickers.map do |t|
        change = ((t.current_price - 100.0) / 100.0 * 100).round(1)
        direction = change >= 0 ? "▲" : "▼"

        # Volume from pressure deltas
        volume = (t.buy_pressure + t.sell_pressure).round(0)

        # Liquidity percentage
        liquidity_pct =
          if t.max_liquidity.to_f > 0
            ((t.liquidity / t.max_liquidity) * 100).round
          else
            0
          end

        "#{t.name.upcase}: #{t.current_price.round(2)} #{direction} #{change.abs}% | VOL #{volume} | LIQ #{liquidity_pct}%"
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

when /^!coffer sell (\w+) (\d+)/
      name = $1.strip
      sell_amount = $2.to_i
      
      sell_logic(user, name, sell_amount)

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

    when /^!coffer invest (?<arg1>.+)\s+(?<arg2>.+)/
      val1 = Regexp.last_match[:arg1]
      val2 = Regexp.last_match[:arg2]

      # Determine which one is the number and which is the name
      if val1 =~ /^\d+$/
        amount = val1.to_i
        name = val2.strip
      else
        amount = val2.to_i
        name = val1.strip
      end

      invest_logic(user, amount, name, is_mod)
    else
      "Unknown coffer command. Use !coffer, !coffer transfer, or !coffer invest."
    end
  end

  private

def self.invest_logic(user, amount, name, is_mod)
  current_market_price = Ticker.price_for(name)
  return "Minimum investment is 10 farthings." if amount < 10

  ticker_exists = Ticker.exists?(name: name.downcase)
  
  # Check if the user ALREADY has this stock
  existing = user.investments.active.find_by("lower(investment_name) = ?", name.downcase)

  if existing
    # Support for adding to an existing position
    buy_more_of_investment(user, amount, existing, current_market_price)
  elsif !ticker_exists
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

def self.sell_logic(user, name, sell_amount)
    investment = user.investments.active.find_by("lower(investment_name) = ?", name.downcase)
    return "Investment '#{name}' not found." unless investment
    return "You must sell at least 1 farthing." if sell_amount <= 0

    # Ensure the user isn't trying to sell more than the cost basis they put in
    # (Or you can interpret sell_amount as the 'shares' value, but usually cost is safer)
    if sell_amount > investment.amount
      return "You only have #{investment.amount.to_i} farthings invested in #{name.upcase}."
    end

    ticker = Ticker.find_by!(name: investment.investment_name.downcase)
    current_market_price = ticker.current_price

    ActiveRecord::Base.transaction do
      # 1. Calculate the 'Proportion' of the investment being sold
      # Since value = (cost / purchase_price) * current_price
      # We find how much of the original cost is being 'liquidated'
      proportion = sell_amount.to_f / investment.amount
      
      # 2. Calculate the payout based on current market performance
      # Payout = (Amount Sold / Purchase Price) * Current Market Price
      shares_sold = sell_amount.to_f / investment.purchase_price
      payout_value = (shares_sold * current_market_price).round(2)
      profit = (payout_value - sell_amount).round(2)

      # 3. Apply Sell Pressure to the Market
      # Pressure is typically shares sold relative to price/liquidity
      ticker.increment!(:sell_pressure, shares_sold)

      # 4. Update User Balance
      CurrencyService.update_balance(
        user: user, 
        amount: payout_value, 
        type: 'investment_sale', 
        metadata: { name: name, cost_basis: sell_amount, profit: profit }
      )

      # 5. Update or Close the Investment record
      if sell_amount == investment.amount
        investment.redeemed!
        "Sold your entire position in '#{name.upcase}' for #{payout_value} farthings! (Profit: #{profit >= 0 ? '+' : ''}#{profit})"
      else
        investment.update!(amount: investment.amount - sell_amount)
        "Sold #{sell_amount} (at cost) of '#{name.upcase}' for #{payout_value} farthings! (Profit: #{profit >= 0 ? '+' : ''}#{profit}). Remaining basis: #{investment.amount.to_i}"
      end
    end
  rescue => e
    "Error processing sale: #{e.message}"
  end

def self.buy_more_of_investment(user, amount, investment, market_price)
  ActiveRecord::Base.transaction do
    # 1. Calculate current "Shares" (Value / Purchase Price)
    old_shares = investment.amount.to_f / investment.purchase_price
    new_shares = amount.to_f / market_price
    total_shares = old_shares + new_shares

    # 2. Calculate New Weighted Average Purchase Price
    total_investment_at_cost = investment.amount + amount
    new_avg_price = total_investment_at_cost / total_shares

    ticker = Ticker.find_by!(name: investment.investment_name.downcase)

    pressure = amount.to_f / ticker.current_price
    ticker.increment!(:buy_pressure, pressure)

    old_shares = investment.amount.to_f / investment.purchase_price
    new_shares = amount.to_f / market_price
    total_shares = old_shares + new_shares

    total_investment_at_cost = investment.amount + amount
    new_avg_price = total_investment_at_cost / total_shares

    # 3. Update the record

    CurrencyService.update_balance(
      user: user,
      amount: -amount,
      type: 'stock_purchase_add'
    )

    investment.update!(
      amount: total_investment_at_cost,
      purchase_price: new_avg_price
    )
  end
  "Added #{amount} to your #{investment.investment_name.upcase} position! New Avg. Price: #{investment.purchase_price.round(2)}"
end

def self.buy_into_investment(user, amount, name, price)
  ActiveRecord::Base.transaction do
    ticker = Ticker.find_by!(name: name.downcase)

    pressure = amount.to_f / price
    ticker.increment!(:buy_pressure, pressure)

    CurrencyService.update_balance(
      user: user,
      amount: -amount,
      type: 'stock_purchase'
    )

    Investment.create!(
      user: user,
      amount: amount,
      investment_name: name,
      purchase_price: price
    )
  end

  "Bought into '#{name}' at market price #{price.round(2)}!"
end


def self.create_new_investment(user, amount, name, price)
  ActiveRecord::Base.transaction do
    ticker = Ticker.create!(
      name: name.downcase,
      current_price: price,
      liquidity: 1_000.0,
      max_liquidity: 1_000.0,
      buy_pressure: 0.0,
      sell_pressure: 0.0
    )

    pressure = amount.to_f / price
    ticker.increment!(:buy_pressure, pressure)

    CurrencyService.update_balance(
      user: user,
      amount: -amount,
      type: 'stock_purchase'
    )

    Investment.create!(
      user: user,
      amount: amount,
      investment_name: name,
      purchase_price: price
    )
  end

  "IPO Alert! '#{name}' listed at #{price} farthings. You bought in with #{amount}!"
end






end