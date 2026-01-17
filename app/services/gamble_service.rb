class GambleService
  WIN_CHANCE = 0.1 
  PAYOUT_MULTIPLIER = 8.4
  COOLDOWN_TIME = 60 # seconds

  @cooldowns = {}

  def self.process_command(user, text, bid = nil, sid = nil)
    if on_cooldown?(user.uid)
      return "Patience often brings better fortune than hurry."
    end

    amount = 0
    case text
    when /^!gamble (\d+)%$/
      percentage = $1.to_f / 100.0
      # Ensure percentage bets are at least 1 farthing if they have it
      amount = [(user.wallet * percentage).floor, 1].max
    when /^!gamble (\d+)$/
      amount = $1.to_i
    when "!gamble all"
      amount = user.wallet
    else
      return "Usage: !gamble <amount>, !gamble <percentage>%, or !gamble all"
    end

    return "Minimum bet is 1 farthing." if amount <= 0
    return "You only have #{user.wallet} farthings!" unless user.can_afford?(amount)

    set_cooldown(user, bid, sid)
    execute_gamble(user, amount)
  rescue CurrencyService::InsufficientFundsError
    "Transaction failed: Insufficient funds."
  end

  private

  def self.execute_gamble(user, bet_amount)
    win = rand <= WIN_CHANCE

    ActiveRecord::Base.transaction do
      if win
        total_return = (bet_amount * PAYOUT_MULTIPLIER).floor
        net_profit = total_return - bet_amount

        CurrencyService.update_balance(
          user: user,
          amount: net_profit,
          type: 'gamble_win',
          metadata: { bet: bet_amount, odds: WIN_CHANCE, multiplier: PAYOUT_MULTIPLIER }
        )
        # Updated message for clarity: Shows the Bet, the Profit, and the New Wallet total
        "✨ The coins clinked your way this time!  You bet #{bet_amount} and won #{net_profit} farthings! Your wallet now holds #{user.reload.wallet} farthings."

      else
        CurrencyService.update_balance(
          user: user,
          amount: -bet_amount,
          type: 'gamble_loss',
          metadata: { bet: bet_amount, odds: WIN_CHANCE }
        )
        "Luck slipped through your fingers like pipe-smoke. You lost #{bet_amount} farthings. (Balance: #{user.reload.wallet})"
      end
    end
  end

  def self.on_cooldown?(uid)
    last_use = @cooldowns[uid]
    last_use && (Time.now - last_use) < COOLDOWN_TIME
  end

  def self.set_cooldown(user, bid, sid)
    @cooldowns[user.uid] = Time.now

    if defined?(EM) && bid && sid
      EM.add_timer(COOLDOWN_TIME) do
        TwitchService.send_chat_message(bid, sid, "@#{user.username}, fortune favors the persistent. Your gamble cooldown has ended!")
      end
    end
  end
end