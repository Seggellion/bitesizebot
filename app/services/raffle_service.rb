# app/services/raffle_service.rb
class RaffleService
  @active_raffle_id = nil
  MAX_PRIZE = 500 # Internal maximum as requested

  def self.process_command(uid, username, bid, text, is_mod)
    case text
    # Capture the flag (-s or -m) and the amount (\d+)
    when /^!raffle\s+(-[sm])\s+(\d+)/i
      return "Only mods can start a raffle." unless is_mod
      return "A raffle is already in progress!" if @active_raffle_id
      
      flag = $1.downcase
      requested_amount = $2.to_i
      
      # Enforce internal maximum
      final_amount = [requested_amount, MAX_PRIZE].min
      
      return start_threaded_raffle(bid, final_amount, flag)

    when "!raffle join"
      return join_raffle(uid, username)
      
    when /^!raffle give\s+(.+)/
      return "Only mods/admins can give points." unless is_mod
      target_username = $1.strip.gsub('@', '')
      return give_points(target_username, 10) # Example default
    end
  end

  def self.start_threaded_raffle(bid, amount, flag)
    host = User.find_by(uid: bid)
    # flag can be used here if you want -s to change the winner logic 
    # currently we follow your "Random 2-4 winners" requirement
    
    raffle = Raffle.create!(host: host, prize_amount: amount, status: 'active')
    @active_raffle_id = raffle.id

    # ✅ 30-second warning
    EM.add_timer(30) do
      announce(bid, "⏳ 30 SECONDS LEFT! Type !raffle join for a share of #{amount} points!")
    end

    # ✅ 15-second warning
    EM.add_timer(45) do
      announce(bid, "⚠️ 15 SECONDS! Last call to join the raffle!")
    end

    # ✅ Final Draw at 60 seconds
    EM.add_timer(60) do
      finalize_raffle(raffle, bid)
    end

    "🎟️ RAFFLE STARTED! Pool: #{amount} points. 2-4 winners will split it in 60s! Type !raffle join to enter."
  end

  # ... join_raffle and announce remain the same ...
  
  def self.join_raffle(uid, username)
    
    raffle = Raffle.find_by(status: 'active')
    return "No active raffle to join!" unless raffle
    
    user = User.find_or_create_by(uid: uid) { |u| u.username = username; u.provider = 'twitch' }
    
    # Safe against duplicates via Model Validation + DB Index
    entry = raffle.raffle_entries.new(user: user)
    if entry.save
      nil 
    else
      "@#{username}, you're already in!"
    end
  end

  def self.finalize_raffle(raffle, bid)
    winners = raffle.select_and_payout_winners!
    @active_raffle_id = nil

    if winners.any?
      names = winners.map { |w| "@#{w.username}" }.join(", ")
      # Calculation for display (payout logic is inside raffle.select_and_payout_winners!)
      each_gets = (raffle.prize_amount.to_f / winners.size).floor
      announce(bid, "🎉 Raffle Over! Winners: #{names}. They each split the pot and receive #{each_gets} points!")
    else
      announce(bid, "Raffle ended, but nobody joined. No points awarded!")
    end
  end

  def self.announce(bid, message)
    bot_user = User.where(provider: 'twitch').where.not(twitch_access_token: nil).first
    return unless bot_user
    
    TwitchService.send_chat_message(bid, bot_user.uid, message)
  end

end