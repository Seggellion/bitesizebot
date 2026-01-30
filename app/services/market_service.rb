class MarketService
  # Constants for the "Feel" of the market
  BASE_VOLATILITY     = 0.03   # Increased from 0.01 for more "spikiness"
  MOMENTUM_DECAY      = 0.92   # How much of the previous move carries over
  PRESSURE_MULTIPLIER = 0.04   # Max impact of player trades
  LIQUIDITY_REGEN     = 0.05   # Rate at which market stabilizes
  PRESSURE_DECAY      = 0.80   # How fast player influence fades

  def self.fluctuate_prices
    Ticker.find_each do |ticker|
      open_price = ticker.current_price.to_f
      # 1. PLAYER INFLUENCE
      # Net pressure is the difference between buys and sells
      net_pressure = ticker.buy_pressure - ticker.sell_pressure
      abs_pressure = net_pressure.abs
      volume       = abs_pressure.round(2)

      # Liquidity acts as friction; more liquidity = slower price movement
      liquidity_factor = [ticker.liquidity, 1].max
      pressure_effect  = Math.tanh(net_pressure / liquidity_factor) * PRESSURE_MULTIPLIER

      # 2. MARKET MOMENTUM (The "Spiky" Chart Logic)
      # We take the previous momentum, decay it slightly, and add a new random "push"
      prev_momentum = ticker.momentum.is_a?(Numeric) ? ticker.momentum : 0.0
      new_push = rand(-BASE_VOLATILITY..BASE_VOLATILITY)
      current_momentum = ((ticker.momentum || 0) * MOMENTUM_DECAY) + new_push

      # 3. PRICE CALCULATION
      # Combine player activity + random walk momentum
      change_percent = pressure_effect + current_momentum
      close_price    = [open_price * (1 + change_percent), 1.0].max

      # 4. VOLATILITY VISUALS (Candlesticks)
      # Randomly generate highs and lows relative to the movement
      high = [open_price, close_price].max * (1 + rand * 0.01)
      low  = [open_price, close_price].min * (1 - rand * 0.01)

      # 5. LIQUIDITY MANAGEMENT
      # Activity consumes liquidity; it regenerates over time
      liquidity_used = abs_pressure * 0.5
      new_liquidity  = ticker.liquidity - liquidity_used + (ticker.max_liquidity * LIQUIDITY_REGEN)

      # 6. PERSISTENCE
      ticker.update!(
previous_price: open_price.to_f.round(4),
        current_price:  close_price.to_f.round(4),
        momentum:       current_momentum.to_f.round(6),
      liquidity:      [[new_liquidity.to_f, ticker.max_liquidity.to_f].min, 10.0].max.round(2),
buy_pressure:   (ticker.buy_pressure.to_f * PRESSURE_DECAY).round(4),
        sell_pressure:  (ticker.sell_pressure.to_f * PRESSURE_DECAY).round(4)
      )

      # 7. HISTORY RECORDING
      ticker.price_histories.create!(
        open:   open_price.to_f.round(4),
        high:   high.to_f.round(4),
        low:    low.to_f.round(4),
        close:  close_price.to_f.round(4),
        price:  close_price.to_f.round(4),
        volume: volume.to_f.round(2)
      )
    end
  end
end