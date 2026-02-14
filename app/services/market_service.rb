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
    # --- 1. PROCESS PENDING SALES (User getting paid) ---
    Investment.pending_sale.includes(:ticker, :user).find_each do |inv|
      execute_sale(inv)
    end

    # --- 2. PROCESS PENDING PURCHASES (User getting stock) ---
    Investment.pending_purchase.includes(:ticker, :user).find_each do |inv|
      execute_purchase(inv)
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
    execution_price = ticker.current_price

    ActiveRecord::Base.transaction do
      existing = investment.user.investments.active.find_by(ticker: ticker)

      if existing
        # Merge into existing position (Weighted Average)
        old_shares = existing.amount.to_f / existing.purchase_price
        new_shares = investment.amount.to_f / execution_price
        total_cost = existing.amount + investment.amount
        
        existing.update!(
          amount: total_cost,
          purchase_price: (total_cost / (old_shares + new_shares))
        )
        investment.destroy! # Clean up the pending record
      else
        # Activate the pending record
        investment.update!(
          status: :active,
          purchase_price: execution_price,
          updated_at: Time.current
        )
      end
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