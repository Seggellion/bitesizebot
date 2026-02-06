# app/services/coffer_service.rb
class CofferService
  def self.process_command(uid, username, text, is_mod = false)
    user = User.find_or_create_by(uid: uid) do |u|
      u.username = username
      u.provider = 'twitch'
      u.user_type = 1
    end

    is_host = User.broadcaster

    case text.downcase
    when "!coffer markets"
      return "Access Denied: System use only for markets display" unless is_mod
      tickers = Ticker.all
      return "The market is currently empty." if tickers.empty?

      ticker_list = tickers.map do |t|
        change = ((t.current_price - 100.0) / 100.0 * 100).round(1)
        direction = change >= 0 ? "▲" : "▼"
        volume = (t.buy_pressure + t.sell_pressure).round(0)
        liquidity_pct = t.max_liquidity.to_f > 0 ? ((t.liquidity / t.max_liquidity) * 100).round : 0

        "#{t.symbol.upcase}: #{t.current_price.round(2)} #{direction} #{change.abs}% | VOL #{volume} | LIQ #{liquidity_pct}%"
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

    # Flexible Regex for both Sell and Invest to support [Amount Ticker] or [Ticker Amount]
    when /^!coffer (?<cmd>sell|invest)\s+(?<arg1>.+)\s+(?<arg2>.+)/
      cmd = Regexp.last_match[:cmd]
      val1 = Regexp.last_match[:arg1]
      val2 = Regexp.last_match[:arg2]

      if val1 =~ /^\d+$/
        amount, name = val1.to_i, val2.strip
      else
        amount, name = val2.to_i, val1.strip
      end

      cmd == "sell" ? sell_logic(user, name, amount) : invest_logic(user, amount, name)

    when /^!coffer multisend -t(\d+)\s+(\d+)/
      return "Access Denied: Only the Host can perform mass grants." unless is_host
      minutes, amount = $1.to_i, $2.to_i
      return "Amount must be greater than 0." if amount <= 0
      
      active_users = User.where("updated_at >= ?", minutes.minutes.ago)
      if active_users.any?
        ActiveRecord::Base.transaction do
          active_users.find_each do |target_user|
            CurrencyService.update_balance(
              user: target_user,
              amount: amount,
              type: 'mass_grant',
              metadata: { trigger_source: 'twitch_command', triggered_by: username, timeframe: minutes }
            )
          end
        end
        "Mass Grant Successful! Sent #{amount} farthings to #{active_users.count} users active in the last #{minutes}m."
      else
        "No users found active in the last #{minutes} minutes."
      end

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

    else
      "Unknown coffer command. Use !coffer, !coffer transfer, !coffer invest, or !coffer sell."
    end
  end

  private

  def self.invest_logic(user, amount, name)
    ticker = Ticker.find_by(symbol: name.upcase)
    return "Ticker '#{name.upcase}' isn't listed in the markets." unless ticker
    return "Minimum investment is 200 farthings." if amount < 200

    current_market_price = ticker.current_price
    existing = user.investments.active.find_by(ticker_id: ticker.id)

    ActiveRecord::Base.transaction do
      # Calculate Purchase Details
      if existing
        old_shares = existing.amount.to_f / existing.purchase_price
        new_shares = amount.to_f / current_market_price
        total_shares = old_shares + new_shares
        total_cost = existing.amount + amount
        new_avg_price = total_cost / total_shares

        existing.update!(amount: total_cost, purchase_price: new_avg_price)
        msg = "Added #{amount} to your #{name.upcase} position! New Avg. Price: #{new_avg_price.round(2)}"
      else
        Investment.create!(
          user: user,
          amount: amount,
          ticker_id: ticker.id,
          investment_name: name.upcase,
          purchase_price: current_market_price
        )
        msg = "Bought into '#{name.upcase}' at market price #{current_market_price.round(2)}!"
      end

      # Update Market and Wallet
      ticker.increment!(:buy_pressure, (amount.to_f / current_market_price))
      CurrencyService.update_balance(user: user, amount: -amount, type: 'stock_purchase')
      
      msg
    end
  rescue CurrencyService::InsufficientFundsError
    "You don't have enough farthings!"
  rescue => e
    "Error processing investment: #{e.message}"
  end

  def self.sell_logic(user, name, sell_amount)
  ticker = Ticker.find_by(symbol: name.upcase)
  investment = user.investments.active.find_by(ticker_id: ticker&.id)

  return "Investment '#{name.upcase}' not found in your portfolio." unless investment
  return "You must sell at least 1 farthing." if sell_amount <= 0
  return "You only have #{investment.amount.to_i} farthings (cost basis) in #{name.upcase}." if sell_amount > investment.amount

  current_market_price = ticker.current_price

  ActiveRecord::Base.transaction do
    shares_sold = sell_amount.to_f / investment.purchase_price
    gross_payout = (shares_sold * current_market_price).round(2)

    # --- Liquidity-scaled sell fee ---
    base_fee_rate = 0.015
    pressure_multiplier = 0.02
    max_fee_rate = 0.05

    liquidity_ratio = ticker.sell_pressure / [ticker.liquidity, 1.0].max
    dynamic_fee_rate = base_fee_rate + (liquidity_ratio * pressure_multiplier)
    fee_rate = [[dynamic_fee_rate, base_fee_rate].max, max_fee_rate].min

    fee_amount = (gross_payout * fee_rate).round(2)
    net_payout = (gross_payout - fee_amount).round(2)
    profit = (net_payout - sell_amount).round(2)

    ticker.increment!(:sell_pressure, shares_sold)

    # --- Credit user for the sale ---
    CurrencyService.update_balance(
      user: user,
      amount: net_payout,
      type: 'stock_sell',
      metadata: {
        ticker: name.upcase,
        gross_payout: gross_payout,
        fee_rate: fee_rate,
        fee_amount: fee_amount,
        cost_basis: sell_amount,
        profit: profit
      }
    )

    # --- Record fee as a separate ledger entry (burn) ---
    CurrencyService.update_balance(
      user: user,
      amount: -fee_amount,
      type: 'market_fee',
      metadata: {
        ticker: name.upcase,
        fee_rate: fee_rate,
        reason: 'liquidity_scaled_sell_fee'
      }
    )

    if sell_amount == investment.amount
      investment.redeemed!
      "Sold entire #{name.upcase} position for #{net_payout} farthings after fees. (Profit: #{profit >= 0 ? '+' : ''}#{profit})"
    else
      investment.update!(amount: investment.amount - sell_amount)
      "Sold #{sell_amount} (cost basis) of #{name.upcase} for #{net_payout} after fees. (Profit: #{profit >= 0 ? '+' : ''}#{profit}). Remaining basis: #{investment.amount.to_i}"
    end
  end
rescue => e
  "Error processing sale: #{e.message}"
end


  
end