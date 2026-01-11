# app/jobs/auto_mint_queue_job.rb
class AutoMintQueueJob < ApplicationJob
  queue_as :default

  PAR = 10.0 # 1 ingot = 10 coins
  MINT_BATCH_SIZE = { "copper" => 5, "silver" => 3, "gold" => 1 } # ingots to mint per run
  MIN_COIN_TARGET = { "copper" => 1000, "silver" => 500, "gold" => 100 }

def perform
  TreasuryBalance.includes(:currency, treasury: :city).find_each do |tb|
    city = tb.treasury.city
    cur = tb.currency.name.downcase
    supply_field = "#{cur}_supply"
    
    # ---------------------------------------------------------
    # STEP 1: REPLENISH THE RESERVE (The "Buffer")
    # ---------------------------------------------------------
    # We want the Treasury to hold a buffer of 5x the batch size (e.g., 25 ingots)
    # This happens regardless of whether we need coins right now.
    
    target_reserve = MINT_BATCH_SIZE[cur] * 5
    current_reserve = tb.reserve.to_i
    
    if current_reserve < target_reserve && city.respond_to?(supply_field)
      # Calculate how much space we have left in the reserve
      space_in_reserve = target_reserve - current_reserve
      
      # Take what is available from city, up to the space we have
      city_supply = city.send(supply_field).to_f
      to_transfer = [city_supply, space_in_reserve].min
      
      if to_transfer > 0
        # WRAP THIS IN A TRANSACTION
        City.transaction do
          city.decrement!(supply_field, to_transfer)
          tb.increment!(:reserve, to_transfer)
        end
        
        # Update local variable only after success
        current_reserve += to_transfer 
      end

    end

    # ---------------------------------------------------------
    # STEP 2: MINT FROM RESERVE (The "Production")
    # ---------------------------------------------------------
    # Now we only look at the Reserve. We don't care about City Supply here.
    
    coins_outstanding = tb.coins_outstanding.to_i
    
    if coins_outstanding < MIN_COIN_TARGET[cur] && current_reserve > 0
      # We can only mint what we actually have in the Reserve
      to_mint_ingots = [current_reserve, MINT_BATCH_SIZE[cur]].min
      
      # FIX: Removed the .max logic that caused infinite money glitch
      to_mint_coins = (to_mint_ingots * PAR).floor
      
      if to_mint_coins > 0
        tb.with_lock do
          tb.reserve -= to_mint_ingots
          tb.coins_outstanding += to_mint_coins
          tb.save!
        end
        
        Rails.logger.info "Minted #{to_mint_coins} #{cur} coins."
      end
    end
  end
end
end
