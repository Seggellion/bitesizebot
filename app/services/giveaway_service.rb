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

    # Regex to capture "!fellowship max" or "!fellowship 10"
    case text.downcase
    when /^!fellowship\s+(.+)/
      param = $1.strip
      
      # Determine current status
      entry = giveaway.giveaway_entries.find_by(user: viewer)
      current_tickets = entry&.tickets_count || 0
      remaining_slots = giveaway.max_entries_per_user - current_tickets

      if remaining_slots <= 0
        return "You already have the maximum of #{giveaway.max_entries_per_user} tickets!"
      end

      if param == 'max'
        # Logic: If 0 tickets, first is free. Max = Wallet + 1.
        # If >0 tickets, Max = Wallet.
        affordable = (current_tickets == 0) ? (viewer.wallet + 1) : viewer.wallet
        amount = [affordable, remaining_slots].min
      else
        amount = param.to_i
      end

      return "Please specify a valid amount of tickets." if amount <= 0
      handle_entry(viewer, giveaway, amount)
    
    when "!fellowship" # Default to 1 ticket
      handle_entry(viewer, giveaway, 1)
    end
  end

  private
  
def self.handle_entry(user, giveaway, amount)
  message = "" # Initialize variable to capture the response
  
  ActiveRecord::Base.transaction do
    entry = giveaway.giveaway_entries.find_by(user: user)
    is_new_entry = entry.nil?
    current_tickets = entry&.tickets_count || 0

    # 1. Validation
    if (current_tickets + amount) > giveaway.max_entries_per_user
      return "You can only add #{giveaway.max_entries_per_user - current_tickets} more ticket(s)."
    end

    # 2. Determine cost
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
        # Explicitly roll back the transaction
        raise ActiveRecord::Rollback, "Insufficient funds"
      end
    end

    # 4. Create or Update
    if is_new_entry
      entry = giveaway.giveaway_entries.create!(user: user, tickets_count: amount)
    else
      entry.update!(tickets_count: entry.tickets_count + amount)
    end

    free_msg = (is_new_entry && amount > 0) ? " (Your first ticket was free!)" : ""
    message = "You added #{amount} ticket(s) to #{giveaway.title}! Total: #{entry.tickets_count}/#{giveaway.max_entries_per_user}#{free_msg}"
  end

  # If message is empty, it means we hit the Rollback
  message.presence || "You don't have enough Lembas! (Cost: #{tickets_to_charge})"
rescue => e
  Rails.logger.error "Giveaway Error: #{e.message}"
  "Something went wrong processing your entry."
end

end