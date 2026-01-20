class MarketUpdateJob
  include Sidekiq::Job

def perform
  # Ensure only one instance of this loop is running in Redis
  lock_key = "market_update_running"
  return if Sidekiq.redis { |r| r.get(lock_key) == "true" && !@recursing }
  
  unless SystemSetting.bot_enabled?
    Sidekiq.redis { |r| r.del(lock_key) }
    return
  end

  Sidekiq.redis { |r| r.setex(lock_key, 600, "true") } # 10 min expiry safety
  
  MarketService.fluctuate_prices
  
  @recursing = true
  self.class.perform_in(5.minutes)
end

end