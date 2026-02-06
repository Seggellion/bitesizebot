class MarketService
  # Constants for the "Feel" of the market
  BASE_VOLATILITY     = 0.03   # Standard spikiness
  MOMENTUM_DECAY      = 0.92   # Carry-over from previous moves
  PRESSURE_MULTIPLIER = 0.04   # Max impact of trades
  LIQUIDITY_REGEN     = 0.05   # Market stabilization rate
  PRESSURE_DECAY      = 0.80   # How fast chat influence fades

  def self.fluctuate_prices
    # Calculate stream progress
    settings = SystemSetting.first
    # Calculate hours since last_enabled_at (default to 0 if nil)
    stream_age_hours = settings&.last_enabled_at ? (Time.current - settings.last_enabled_at) / 3600.0 : 0.0

    Ticker.find_each do |ticker|
      open_price = ticker.current_price.to_f

      # --- MARKET PHASE CALCULATIONS ---
      
      # 1. HYPE FACTOR (Bell Curve)
      # Peaks at 1.0 when stream_age_hours is exactly 2.0. 
      # Declines towards 0 as you move away from that center.
      hype_factor = Math.exp(-((stream_age_hours - 2)**2) / (2 * 1.0**2))
      
      # 2. CLOSING PRESSURE (Exit Liquidity)
      # As the stream hits the 3-hour mark, users start "selling off."
      # This adds artificial sell pressure that scales up toward the 4th hour.
      closing_panic = stream_age_hours > 3.0 ? (stream_age_hours - 3.0) * 3.0 : 0.0

      # 3. PLAYER INFLUENCE
      # We amplify the existing buy_pressure during the hype peak
      adjusted_buy  = ticker.buy_pressure.to_f * (1 + hype_factor)
      adjusted_sell = ticker.sell_pressure.to_f + closing_panic
      
      net_pressure = adjusted_buy - adjusted_sell
      abs_pressure = net_pressure.abs
      volume       = abs_pressure.round(2)

      # Liquidity acts as friction
      liquidity_factor = [ticker.liquidity, 1].max
      pressure_effect  = Math.tanh(net_pressure / liquidity_factor) * PRESSURE_MULTIPLIER

      # 4. MARKET MOMENTUM (The "Spiky" Chart Logic)
      # We increase volatility slightly during the hype phase
      phase_volatility = BASE_VOLATILITY * (1 + (hype_factor * 0.5))
      
      prev_momentum = ticker.momentum.is_a?(Numeric) ? ticker.momentum : 0.0
      new_push = rand(-phase_volatility..phase_volatility)
      current_momentum = (prev_momentum * MOMENTUM_DECAY) + new_push

      # 5. PRICE CALCULATION
      change_percent = pressure_effect + current_momentum
      close_price    = [open_price * (1 + change_percent), 0.01].max

      # 6. VOLATILITY VISUALS (Candlesticks)
      high = [open_price, close_price].max * (1 + rand * (phase_volatility * 0.3))
      low  = [open_price, close_price].min * (1 - rand * (phase_volatility * 0.3))

      # 7. LIQUIDITY MANAGEMENT
      liquidity_used = abs_pressure * 0.5
      new_liquidity  = ticker.liquidity - liquidity_used + (ticker.max_liquidity * LIQUIDITY_REGEN)

      # 8. PERSISTENCE
      ticker.update!(
        previous_price: open_price.round(4),
        current_price:  close_price.round(4),
        momentum:       current_momentum.round(6),
        liquidity:      [[new_liquidity.to_f, ticker.max_liquidity.to_f].min, 10.0].max.round(2),
        buy_pressure:   (ticker.buy_pressure.to_f * PRESSURE_DECAY).round(4),
        sell_pressure:  (ticker.sell_pressure.to_f * PRESSURE_DECAY).round(4)
      )

      # 9. HISTORY RECORDING
      ticker.price_histories.create!(
        open:   open_price.round(4),
        high:   high.round(4),
        low:    low.round(4),
        close:  close_price.round(4),
        price:  close_price.round(4),
        volume: volume.round(2)
      )
    end
  end
end