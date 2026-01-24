# app/services/market_service.rb
class MarketService
  def self.fluctuate_prices
    Ticker.find_each do |ticker|
      old_price = ticker.current_price
      
      # 90% chance of normal fluctuation, 10% chance of high volatility
      volatility = rand < 0.90 ? 0.05 : 0.20
      
      # Calculate change
      change_percent = rand(-volatility..volatility + 0.01) # Slight upward bias
      new_price = old_price * (1 + change_percent)
      
      ticker.update!(
        previous_price: old_price,
        current_price: [new_price, 1.0].max
      )
      ticker.price_histories.create!(price: new_price)
    end
  end
end