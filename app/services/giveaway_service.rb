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

    # We use a variable 'result' to ensure the logic returns a string back to the bot
    result = case text.downcase.strip
             when /^!fellowship\s+(.+)/, /^!lembas\s+(.+)/
               param = $1.strip
               
               # Determine current status for 'max' calculation
               entry = giveaway.giveaway_entries.find_by(user: viewer)
               current_tickets = entry&.tickets_count || 0
               remaining_slots = giveaway.max_entries_per_user - current_tickets

               if remaining_slots <= 0
                 "You already have the maximum of #{giveaway.max_entries_per_user} tickets!"
               elsif param == 'max'
                 # Logic: If 0 tickets, first is free. Max affordable = Wallet + 1.
                 # If user already has tickets, Max affordable = Wallet.
                 # Then we cap it by the remaining slots allowed in the giveaway.
                 affordable = (current_tickets == 0) ? (viewer.wallet + 1) : viewer.wallet
                 amount = [affordable, remaining_slots].min
                 
                 amount <= 0 ? "You can't afford any more tickets!" : handle_entry(viewer, giveaway, amount)
               else
                 amount = param.to_i
                 amount <= 0 ? "Please specify a valid amount." : handle_entry(viewer, giveaway, amount)
               end

             when "!fellowship"
               # Default to adding 1 ticket
               handle_entry(viewer, giveaway, 1)
             else
               nil # Not a recognized giveaway command
             end

    return result
  end

  private

  def self.handle_entry(user, giveaway, amount)
    message = ""
    
    ActiveRecord::Base.transaction do
      # Reload user to get the latest wallet balance and prevent race conditions
      user.reload
      
      entry = giveaway.giveaway_entries.find_by(user: user)
      is_new_entry = entry.nil?
      current_tickets = entry&.tickets_count || 0

      # 1. Validation: Ensure they don't exceed the global max
      if (current_tickets + amount) > giveaway.max_entries_per_user
        return "You can only add #{giveaway.max_entries_per_user - current_tickets} more ticket(s)."
      end

      # 2. Determine cost: First ticket is free for new entries
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
          # Rollback the transaction so the entry is NOT created/updated
          raise ActiveRecord::Rollback, "Insufficient funds"
        end
      end

      # 4. Create or Update the record
      if is_new_entry
        entry = giveaway.giveaway_entries.create!(user: user, tickets_count: amount)
      else
        entry.update!(tickets_count: entry.tickets_count + amount)
      end

      free_msg = (is_new_entry && amount > 0) ? " (Your first ticket was free!)" : ""
      message = "You added #{amount} ticket(s) to #{giveaway.title}! Total: #{entry.tickets_count}/#{giveaway.max_entries_per_user}#{free_msg}"
    end

    # If message is empty, it means the transaction rolled back due to funds
    message.presence || "You don't have enough Lembas!"
  rescue => e
    Rails.logger.error "Giveaway Error: #{e.message}"
    "Something went wrong processing your entry."
  end
end