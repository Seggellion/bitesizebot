class MarketService
  BASE_VOLATILITY     = 0.01
  PRESSURE_MULTIPLIER = 0.04
  LIQUIDITY_REGEN     = 0.05
  PRESSURE_DECAY      = 0.80

  def self.fluctuate_prices
    Ticker.find_each do |ticker|
      open_price = ticker.current_price

      net_pressure = ticker.buy_pressure - ticker.sell_pressure
      abs_pressure = net_pressure.abs

      # Volume is how much pressure actually hit the market
      volume = abs_pressure.round(2)

      # Liquidity dampens price movement
      liquidity_factor = [ticker.liquidity, 1].max
      pressure_effect =
        Math.tanh(net_pressure / liquidity_factor) * PRESSURE_MULTIPLIER

      random_drift = rand(-BASE_VOLATILITY..BASE_VOLATILITY)

      change_percent = pressure_effect + random_drift
      close_price = [open_price * (1 + change_percent), 1.0].max

      high = [open_price, close_price].max * (1 + rand * 0.01)
      low  = [open_price, close_price].min * (1 - rand * 0.01)

      # Liquidity is consumed by activity
      liquidity_used = abs_pressure * 0.5
      new_liquidity =
        ticker.liquidity - liquidity_used +
        (ticker.max_liquidity * LIQUIDITY_REGEN)

      ticker.update!(
        previous_price: open_price,
        current_price: close_price,
        liquidity: [[new_liquidity, ticker.max_liquidity].min, 10].max,
        buy_pressure: ticker.buy_pressure * PRESSURE_DECAY,
        sell_pressure: ticker.sell_pressure * PRESSURE_DECAY
      )

      ticker.price_histories.create!(
        open: open_price,
        high: high,
        low: low,
        close: close_price,
        price: close_price,
        volume: volume
      )
    end
  end
end
