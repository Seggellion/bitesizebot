class ActivityEngine
  # Mapping of Twitch usernames to market impact
  INFLUENCERS = {
    "seggellion" => { symbol: "ALT", impact: 1.0, type: :buy },
    "travin72"   => { symbol: "RUM", impact: 3.5, type: :buy },
    "fud_master" => { symbol: "ALT", impact: 2.0, type: :sell }
  }

  def self.process_chat(username)
    # 1. Normalize username for lookup
    influence = INFLUENCERS[username.downcase]
    return unless influence

    # 2. Calculate time-based hype multiplier
    # Impact is amplified the closer the stream is to its 2-hour peak
    multiplier = calculate_time_multiplier

    # 3. Apply the market shift with the multiplier
    apply_pressure(
      influence[:symbol], 
      influence[:impact] * multiplier, 
      influence[:type]
    )
  end

  # Keeps the SHIR buy_pressure synced with total viewers
  def self.sync_viewer_pressure(viewer_count)
    ticker = Ticker.find_by(symbol: "SHIR")
    return unless ticker

    current_val = ticker.buy_pressure.to_f
    target_val  = viewer_count.to_f
    diff = target_val - current_val

    # Only update if there is a difference to save database cycles
    ticker.increment!(:buy_pressure, diff) if diff != 0
  end

  private

  def self.calculate_time_multiplier
    settings = SystemSetting.first
    return 1.0 unless settings&.last_enabled_at

    # Calculate stream age in hours
    stream_age_hours = (Time.current - settings.last_enabled_at) / 3600.0

    # Gaussian Bell Curve logic:
    # Peaks at 2.0x impact at the 2-hour mark.
    # Returns to ~1.0x impact at 0 hours and 4 hours.
    # Formula: 1 + e^(- (age - 2)^2 / 2)
    hype_boost = Math.exp(-((stream_age_hours - 2)**2) / 2.0)
    
    1.0 + hype_boost
  end

  def self.apply_pressure(symbol, amount, type)
    ticker = Ticker.find_by(symbol: symbol)
    return unless ticker

    column = type == :buy ? :buy_pressure : :sell_pressure
    
    # Rounded to 4 decimals to keep the database clean
    ticker.increment!(column, amount.to_f.round(4))
  end
end