# app/services/giveaway_service.rb
class GiveawayService
  def self.process_command(uid, username, broadcaster_uid, text)
    host = User.find_by(uid: broadcaster_uid)
    viewer = User.find_or_create_by(uid: uid) do |u|
      u.provider = 'twitch'
      u.username = username
    end

    # Find the most recently created open giveaway
    giveaway = Giveaway.where(status: 'open').order(created_at: :desc).first
    return "There are no active giveaways to join right now!" unless giveaway

    # Eligibility Checks
    return "You are banned from giveaways." if viewer.respond_to?(:banned_from_giveaways?) && viewer.banned_from_giveaways?
    return "You won too recently! (6-month cooldown)" if viewer.won_recently?(6.months)
    return "You don't meet the Karma/Fame requirements." if viewer.karma < giveaway.min_karma || viewer.fame < giveaway.min_fame

    case text.downcase
    when "!fellowship"
      handle_entry(viewer, giveaway, 1)
    when /^!lembas\s+(.+)/
      amt_param = $1.strip
      amount = amt_param == 'max' ? viewer.wallet : amt_param.to_i
      
      return "Please specify a valid amount of Lembas." if amount <= 0
      handle_entry(viewer, giveaway, amount)
    end
  end
  
  private

  def self.handle_entry(user, giveaway, amount)
    ActiveRecord::Base.transaction do
      entry = giveaway.giveaway_entries.find_or_initialize_by(user: user)
      
      # Logic: First time this user account EVER joins a giveaway, the first ticket is free.
      # We check ledger entries to see if they've ever paid for a giveaway before.
      is_first_join_ever = !user.ledger_entries.where(entry_type: 'giveaway_entry').exists?
      
      tickets_to_charge = is_first_join_ever ? (amount - 1) : amount
      tickets_to_charge = [0, tickets_to_charge].max

      if tickets_to_charge > 0
        begin
          CurrencyService.update_balance(
            user: user,
            amount: -tickets_to_charge,
            type: 'giveaway_entry',
            metadata: { giveaway_id: giveaway.id }
          )
        rescue CurrencyService::InsufficientFundsError
          return "You don't have enough Lembas! (Cost: #{tickets_to_charge})"
        end
      end

      entry.tickets_count += amount
      entry.save!

      free_msg = is_first_join_ever ? " (Your first ticket was free!)" : ""
      "You added #{amount} ticket(s) to #{giveaway.title}! Total: #{entry.tickets_count}#{free_msg}"
    end
  end
end