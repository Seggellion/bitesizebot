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
    return "There’s no feast or gift-giving happening in the Shire just now." unless giveaway

    # We use a variable 'result' to ensure the logic returns a string back to the bot
    result = case text.downcase.strip
             when /^!fellowship\s+(.+)/, /^!lembas\s+(.+)/
               param = $1.strip
               
               # Determine current status for 'max' calculation
               entry = giveaway.giveaway_entries.find_by(user: viewer)
               current_tickets = entry&.tickets_count || 0
               limit = giveaway.max_entries_per_user
              remaining_slots = limit ? (limit - current_tickets) : Float::INFINITY
               cost_per_ticket = giveaway.ticket_cost

               if remaining_slots <= 0
                 "Easy there, my friend. You already hold your full share of #{giveaway.max_entries_per_user} tickets."
               elsif param == 'max'
                 # Logic: If 0 tickets, first is free. Max affordable = Wallet + 1.
                 # If user already has tickets, Max affordable = Wallet.
                 # Then we cap it by the remaining slots allowed in the giveaway.
                 has_lifetime_history = viewer.giveaway_entries.exists?
                 virtual_wallet = viewer.wallet + (has_lifetime_history ? 0 : cost_per_ticket)

                 buying_power = (virtual_wallet / cost_per_ticket).floor
                 
                 amount = [buying_power, remaining_slots].min.to_i

                 amount <= 0 ?
                   "Alas! Your pockets are bare of Lembas. Each token costs #{cost_per_ticket}." :
                   handle_entry(viewer, giveaway, amount)
               else
                 amount = param.to_i
                 amount <= 0 ?
                   "You’ll need to name a proper number, not riddles and nonsense." :
                   handle_entry(viewer, giveaway, amount)
               end

             when "!fellowship"
               # Default to adding 1 ticket
               handle_entry(viewer, giveaway, 1)
             else
               nil # Not a recognized giveaway command
             end

    result
  end

  private

  def self.handle_entry(user, giveaway, amount)
    message = ""
    cost_per_ticket = giveaway.ticket_cost
    
    ActiveRecord::Base.transaction do
      user.reload
      
      entry = giveaway.giveaway_entries.find_by(user: user)
      is_new_entry = entry.nil?
      current_tickets = entry&.tickets_count || 0
      limit = giveaway.max_entries_per_user

      # Validation - Only check limit if it exists
      if limit && (current_tickets + amount) > limit
        return "You may only add #{limit - current_tickets} more token(s) before the mathom chest is full."
      end

      has_lifetime_history = user.giveaway_entries.exists?

      # Determine cost: First ticket is free for first-timers
      tickets_to_charge = has_lifetime_history ? amount : (amount - 1)
      tickets_to_charge = [0, tickets_to_charge].max
      
      total_cost = tickets_to_charge * cost_per_ticket

      # Handle Payment
      if total_cost > 0
        begin
          CurrencyService.update_balance(
            user: user,
            amount: -total_cost,
            type: 'giveaway_entry',
            metadata: { giveaway_id: giveaway.id, ticket_count: amount }
          )
        rescue CurrencyService::InsufficientFundsError
          raise ActiveRecord::Rollback, "Insufficient funds"
        end
      end

      # Create or Update Entry
      if is_new_entry
        entry = giveaway.giveaway_entries.create!(user: user, tickets_count: amount)
      else
        entry.update!(tickets_count: entry.tickets_count + amount)
      end

      free_msg = (!has_lifetime_history && amount > 0) ?
        " (Your first ticket was gifted, as is Shire tradition!)" :
        ""

      message = "You tuck away #{amount} ticket(s), spending #{total_cost} Lembas. "\
                "You now hold #{entry.tickets_count}/#{giveaway.max_entries_per_user}#{free_msg}"
    end

    message.presence || "You don’t seem to have enough Lembas. The going rate is #{cost_per_ticket} per token."
  rescue => e
    Rails.logger.error "Giveaway Error: #{e.message}"
    "Something went awry on the road. Best try again after a second breakfast."
  end
end
