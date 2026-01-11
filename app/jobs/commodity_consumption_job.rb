# app/jobs/commodity_consumption_job.rb
class CommodityConsumptionJob < ApplicationJob
  queue_as :default

  require 'net/http'
  require 'json'
  require 'uri'
def perform
    cities_data = City.find_each.map do |city|
      # 1. Update population based on NPC count
      city.update(population: city.npcs.count)

      # 2. Consume resources (lowers food_supply)
      city.consume_commodities!

      # 3. NEW: Calculate and save starvation status
      # We check if food is depleted AND if there are actually people to starve.
      is_starving = city.food_supply <= 0 && city.population > 0
      city.update(is_starving: is_starving)

      treasury = city.treasury&.treasury_balances&.joins(:currency)
      
      {
        name: city.name,
        treasury: {
          gold:   treasury&.find_by(currencies: { name: 'gold' })&.coins_outstanding.to_i,
          silver: treasury&.find_by(currencies: { name: 'silver' })&.coins_outstanding.to_i,
          copper: treasury&.find_by(currencies: { name: 'copper' })&.coins_outstanding.to_i
        },
        food_supply:        city.food_supply.to_f,
        wood_supply:        city.wood_supply.to_f,
        metal_supply:       city.metal_supply.to_f,
        stone_supply:       city.stone_supply.to_f,
        textile_supply:     city.textile_supply.to_f,
        alcohol_supply:     city.alcohol_supply.to_f,
        technology_supply:  city.technology_supply.to_f,
        is_starving:        city.is_starving
      }
    end

    payload = { cities: cities_data }

    send_population_update(payload)
  end

  private

    def send_population_update(payload)
    shard_secret = Shard.find_by_name("Britannia").client_secret
        server_url = Setting.get("server_url") + ":8081/api/population_update"

    uri = URI.parse(server_url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request['X-Britannia-Secret'] = shard_secret
    request.body = payload.to_json

    response = http.request(request)
    Rails.logger.info "Sent population update: #{response.code}"
    rescue => e
    Rails.logger.error "Failed to send update to Minecraft: #{e.message}"
    end

end
