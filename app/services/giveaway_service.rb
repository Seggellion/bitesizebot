# app/services/giveaway_service.rb
class GiveawayService
  def self.process_command(uid, username, broadcaster_uid, text)
    host = User.find_by(uid: broadcaster_uid)
    viewer = User.find_or_create_by(uid: uid) do |u|
      u.provider = 'twitch'
      u.username = username
      u.user_type = 1
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
    # 1. Check if they are already in THIS giveaway
    entry = giveaway.giveaway_entries.find_by(user: user)
    is_new_entry = entry.nil?

    # 2. Determine cost
    # If they are new, the first ticket of the 'amount' is free.
    # If they already have an entry, they must pay for every ticket in 'amount'.
    tickets_to_charge = is_new_entry ? (amount - 1) : amount
    tickets_to_charge = [0, tickets_to_charge].max

    # 3. Handle Payment
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

    # 4. Create or Update the record
    if is_new_entry
      entry = giveaway.giveaway_entries.create!(user: user, tickets_count: amount)
    else
      entry.update!(tickets_count: entry.tickets_count + amount)
    end

    free_msg = is_new_entry ? " (Your first ticket was free!)" : ""
    "You added #{amount} ticket(s) to #{giveaway.title}! Total: #{entry.tickets_count}#{free_msg}"
  end
end

end