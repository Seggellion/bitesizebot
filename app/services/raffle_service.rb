# app/services/raffle_service.rb
class RaffleService
  @active_raffle_id = nil
  MAX_PRIZE = 500 # Internal maximum as requested

  def self.process_command(uid, username, bid, text, is_mod)
    case text
    # Capture the flag (-s or -m) and the amount (\d+)
    when /^!gimme\s+(-[sm])\s+(\d+)/i

    unless is_mod
        return "Be off with you! You haven't the authority of a Mayor or a Bounder to start a raffle in this Shire."
    end

        return "A raffle is already in progress!" if @active_raffle_id
      
      flag = $1.downcase
      requested_amount = $2.to_i
      
      # Enforce internal maximum
      final_amount = [requested_amount, MAX_PRIZE].min
      
      return start_threaded_raffle(bid, final_amount, flag)
      
    when /^!gimme give\s+@?(\w+)\s+(\d+)/i
        # SECURITY: Only the Broadcaster (uid == bid) can manually give points
        unless uid.to_s == bid.to_s
        return "Only the High Mayor (Broadcaster) has the keys to the treasury!"
        end

        target_username = $1.downcase
        amount = $2.to_i

        return give_points(target_username, amount)

    when /^!gimme give\s+@?(\w+)/i
        # Fallback for when no amount is specified (defaults to 10)
        unless uid.to_s == bid.to_s
        return "Only the High Mayor can distribute points."
        end

        target_username = $1.downcase
        return give_points(target_username, 10)

    when "!gimme"
        return join_raffle(uid, username)
      
    end
  end

def self.start_threaded_raffle(bid, amount, flag)
  host = User.find_by(uid: bid)
  raffle = Raffle.create!(host: host, prize_amount: amount, status: 'active', raffle_type: flag)
  
  # ✅ ADD THIS: Track the active raffle ID so the "already in progress" check works
  @active_raffle_id = raffle.id
  
  job_class = "RaffleFinalizerJob".constantize
  job_class.set(wait: 30.seconds).perform_later(raffle.id, bid, 'warning_30')
  job_class.set(wait: 45.seconds).perform_later(raffle.id, bid, 'warning_15')
  job_class.set(wait: 60.seconds).perform_later(raffle.id, bid, 'finalize')

  mode_text = (flag == '-s') ? "One lucky winner takes it all!" : "2-4 winners will split the pot!"
  "🎟️ RAFFLE STARTED! Pool: #{amount} points. #{mode_text} Type !gimme to enter."
end

  # app/services/raffle_service.rb

def self.give_points(target_username, amount)
  # Find user case-insensitively
  user = User.find_by('lower(username) = ?', target_username.downcase)
  return "User #{target_username} hasn't visited the Shire yet!" unless user

  begin
    # Use a transaction to ensure both the entry and the wallet update succeed together
    ActiveRecord::Base.transaction do
      user.ledger_entries.create!(
        amount: amount,
        entry_type: 'manual_grant',
        metadata: { 
          reason: "Broadcaster manual grant", 
          source: "raffle_service" 
        }
      )
      
      # Update the wallet balance
      user.increment!(:wallet, amount)
    end

    "💰 @#{user.username} has been granted #{amount} points! New balance: #{user.wallet}"
  rescue ActiveRecord::RecordInvalid => e
    "❌ Failed to grant points: #{e.message}"
  rescue StandardError => e
    "❌ An error occurred: #{e.message}"
  end
end

  
  def self.join_raffle(uid, username)
    
    raffle = Raffle.find_by(status: 'active')
    return "No active raffle to join!" unless raffle
    
    user = User.find_or_create_by(uid: uid) { |u| u.username = username; u.provider = 'twitch'; u.user_type = 1 }
    
    # Safe against duplicates via Model Validation + DB Index
    entry = raffle.raffle_entries.new(user: user)
    if entry.save
      nil 
    else
      "@#{username}, you're already in!"
    end
  end

 # app/services/raffle_service.rb
def self.finalize_raffle(raffle, bid)
  winners = raffle.select_and_payout_winners!
  raffle.update(status: 'completed') 
  @active_raffle_id = nil
  Rails.cache.delete("active_raffle_#{bid}")

  if winners.any?
    names = winners.map { |w| "@#{w.username}" }.join(", ")
    each_gets = (raffle.prize_amount.to_f / winners.size).floor
    
    msg = if winners.size > 1
            "🎉 Raffle Over! Winners: #{names}. They split the pot and receive #{each_gets} points each!"
          else
            "🎉 Raffle Over! @#{winners.first.username} won the jackpot of #{each_gets} points!"
          end
          
    announce(bid, msg)
  else
    announce(bid, "Raffle ended, but nobody joined. No points awarded!")
  end
end

  def self.announce(bid, message)
    bot_user = User.bot_user
    return unless bot_user
    
    TwitchService.send_chat_message(bid, bot_user.uid, message)
  end


end


