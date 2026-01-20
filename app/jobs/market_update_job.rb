# app/sidekiq/market_update_job.rb
class MarketUpdateJob
  include Sidekiq::Job

  def perform
    lock_key = "market_update_running"
    
    # Check if another loop is already running
    is_running = Sidekiq.redis { |r| r.get(lock_key) }
    
    # If the bot is turned off, clear the lock and stop
    unless SystemSetting.bot_enabled?
      Sidekiq.redis { |r| r.del(lock_key) }
      return
    end

    # Modern Redis 'set' with expiration (ex: 600 seconds)
    # nx: true means "Only set if it doesn't exist" (Atomic Locking)
    # We allow the set if it's already "true" to refresh the heartbeat
    Sidekiq.redis { |r| r.set(lock_key, "true", ex: 600) }
    
    # Run the market logic
    MarketService.fluctuate_prices
    
    # Schedule the next tick
    self.class.perform_in(5.minutes)
  end
end