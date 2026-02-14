class MarketService
  # Constants for the "Feel" of the market
  BASE_VOLATILITY     = 0.03
  MOMENTUM_DECAY      = 0.92
  PRESSURE_MULTIPLIER = 0.04
  LIQUIDITY_REGEN     = 0.05
  PRESSURE_DECAY      = 0.80

  # This is the "Master" method that should be called by your cron/job
  def self.tick
    ActiveRecord::Base.transaction do
      fluctuate_prices
      process_pending_orders
    end
  end

  def self.fluctuate_prices
    settings = SystemSetting.first
    stream_age_hours = settings&.last_enabled_at ? (Time.current - settings.last_enabled_at) / 3600.0 : 0.0

    Ticker.find_each do |ticker|
      open_price = ticker.current_price.to_f

      # 1. Hype & Panic Logic
      hype_factor = Math.exp(-((stream_age_hours - 2)**2) / (2 * 1.0**2))
      closing_panic = stream_age_hours > 3.0 ? (stream_age_hours - 3.0) * 3.0 : 0.0

      # 2. Player Influence (Buy/Sell Pressure)
      adjusted_buy  = ticker.buy_pressure.to_f * (1 + hype_factor)
      adjusted_sell = ticker.sell_pressure.to_f + closing_panic
      
      net_pressure = adjusted_buy - adjusted_sell
      abs_pressure = net_pressure.abs
      volume       = abs_pressure.round(2)

      liquidity_factor = [ticker.liquidity, 1].max
      pressure_effect  = Math.tanh(net_pressure / liquidity_factor) * PRESSURE_MULTIPLIER

      # 3. Momentum & Phase Volatility
      phase_volatility = BASE_VOLATILITY * (1 + (hype_factor * 0.5))
      prev_momentum = ticker.momentum.is_a?(Numeric) ? ticker.momentum : 0.0
      current_momentum = (prev_momentum * MOMENTUM_DECAY) + rand(-phase_volatility..phase_volatility)

      # 4. Price Finalization
      change_percent = pressure_effect + current_momentum
      close_price    = [open_price * (1 + change_percent), 0.01].max

      # 5. Persistence & Decay
      ticker.update!(
        previous_price: open_price.round(4),
        current_price:  close_price.round(4),
        momentum:       current_momentum.round(6),
        liquidity:      [[ticker.liquidity - (abs_pressure * 0.5) + (ticker.max_liquidity * LIQUIDITY_REGEN), ticker.max_liquidity.to_f].min, 10.0].max.round(2),
        buy_pressure:   (ticker.buy_pressure.to_f * PRESSURE_DECAY).round(4),
        sell_pressure:  (ticker.sell_pressure.to_f * PRESSURE_DECAY).round(4)
      )

      # 6. History
      ticker.price_histories.create!(
        open: open_price, high: [open_price, close_price].max, 
        low: [open_price, close_price].min, close: close_price, 
        price: close_price, volume: volume
      )
    end
  end

def self.process_pending_orders
  affected_users = Set.new

  Investment.where(status: [:pending_sale, :pending_purchase]).find_each do |inv|
    affected_users << inv.user
    inv.status == "pending_sale" ? execute_sale(inv) : execute_purchase(inv)
  end

  # Now that the whole market has moved, pulse every user's wallet ONCE
  affected_users.each do |user|
    user.broadcast_replace_to user,
      target: "user_wallet_balance",
      html: "<span class='animate-wallet-update text-sm font-mono text-green-400'>ƒ #{ActionController::Base.helpers.number_with_delimiter(user.reload.wallet)}</span>"
  end
end

  private

  def self.execute_sale(investment)
    ticker = investment.ticker
    current_market_price = ticker.current_price

    shares_sold = investment.amount.to_f / investment.purchase_price
    gross_payout = (shares_sold * current_market_price).round(2)

    # Fee Logic
    fee_rate = calculate_fee_rate(ticker)
    fee_amount = (gross_payout * fee_rate).round(2)
    net_payout = (gross_payout - fee_amount).round(2)

    ActiveRecord::Base.transaction do
      CurrencyService.update_balance(
        user: investment.user,
        amount: net_payout.to_i,
        type: 'stock_sell',
        metadata: { ticker: ticker.symbol, fee_amount: fee_amount }
      )
      investment.update!(status: :redeemed)
    end
  end

def self.execute_purchase(investment)
  ticker = investment.ticker
  user = investment.user
  execution_price = ticker.current_price
  final_ledger = nil # Initialize variable to use after transaction

  ActiveRecord::Base.transaction do
    # 1. Finalize the Investment
    existing = user.investments.active.find_by(ticker: ticker)

    if existing
      old_shares = existing.amount.to_f / existing.purchase_price
      new_shares = investment.amount.to_f / execution_price
      total_cost = existing.amount + investment.amount
      
      existing.update!(
        amount: total_cost,
        purchase_price: (total_cost / (old_shares + new_shares))
      )
      investment.destroy!
      final_type = 'stock_purchase_add'
    else
      investment.update!(
        status: :active,
        purchase_price: execution_price,
        updated_at: Time.current
      )
      final_type = 'stock_buy'
    end


    # 2. Finalize the Ledger Entry (More robust lookup)
    # We look for the most recent queued entry for this user.
    # We check both metadata formats to be safe.
    final_ledger = user.ledger_entries
                       .where(entry_type: 'stock_purchase_queued')
                       .order(created_at: :desc)
                       .find { |l| l.metadata["ticker"] == ticker.symbol }

    if final_ledger
      final_ledger.update!(
        entry_type: final_type,
        metadata: final_ledger.metadata.merge({
          execution_price: execution_price,
          finalized_at: Time.current
        })
      )
    end
  end

  # 3. THE BROADCASTS (Moved OUTSIDE the transaction for safety)
  if final_ledger
    # Update Global Feed
    final_ledger.broadcast_prepend_to "global_ledger",
      target: "ledger_entries",
      partial: "Hobbit/views/shared/entry", 
      locals: { entry: final_ledger }

    # Pulse User Wallet
    user.broadcast_replace_to user,
      target: "user_wallet_balance",
      html: "<span class='animate-wallet-update text-sm font-mono text-green-400'>ƒ #{ActionController::Base.helpers.number_with_delimiter(user.reload.wallet)}</span>"
  end
end

  def self.calculate_fee_rate(ticker)
    base_fee_rate = 0.015
    max_fee_rate = 0.05
    liquidity_ratio = ticker.sell_pressure / [ticker.liquidity, 1.0].max
    dynamic_fee = base_fee_rate + (liquidity_ratio * 0.02)
    [[dynamic_fee, base_fee_rate].max, max_fee_rate].min
  end
end