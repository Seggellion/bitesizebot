# app/services/coffer_service.rb
class CofferService
  def self.process_command(uid, username, text, is_mod = false)
    user = User.find_or_create_by(uid: uid) do |u|
      u.username = username
      u.provider = 'twitch'
    end

    # pineapple
    is_host = (uid == "136591885")

    case text.downcase
    when "!coffer"
      "Your balance is #{user.wallet} farthings."

    when /^!coffer redeem (.+)/
    name = $1.strip
    investment = user.investments.active.find_by("lower(investment_name) = ?", name.downcase)
    
    return "Investment '#{name}' not found." unless investment

    ActiveRecord::Base.transaction do
        final_amount = investment.current_value
        
        # 1. Add the total (principal + interest) back to balance
        CurrencyService.update_balance(
        user: user, 
        amount: final_amount, 
        type: 'investment_redemption', 
        metadata: { name: name, principal: investment.amount, interest: investment.profit }
        )
        
        # 2. Close the investment
        investment.redeemed!
        "Redeemed '#{name}' for #{final_amount} farthings! (Profit: +#{investment.profit})"
    end

    # MULTISEND START

    when /^!coffer multisend -t(\d+)\s+(\d+)/
      return "Access Denied: Only the Host can perform mass grants." unless is_host
      
      minutes = $1.to_i
      amount = $2.to_i
      
      return "Amount must be greater than 0." if amount <= 0
      
      # Logic: Find users updated within the last X minutes
      active_users = User.where("updated_at >= ?", minutes.minutes.ago)
      
      if active_users.any?
        # Using a transaction for database integrity
        ActiveRecord::Base.transaction do
          active_users.find_each do |target_user|
            CurrencyService.update_balance(
              user: target_user,
              amount: amount,
              type: 'mass_grant',
              metadata: { 
                trigger_source: 'twitch_command', 
                triggered_by: username,
                timeframe: minutes 
              }
            )
          end
        end
        "Mass Grant Successful! Sent #{amount} farthings to #{active_users.count} users active in the last #{minutes}m."
      else
        "No users found active in the last #{minutes} minutes."
      end

      # EOL multisend

    when /^!coffer transfer (\d+) (\w+)/
      amount = $1.to_i
      receiver_name = $2.delete('@')
receiver = User.find_by("LOWER(username) = ?", receiver_name.downcase)

      return "User #{receiver_name} not found." unless receiver
      return "You can't transfer to yourself!" if receiver == user

      begin
        CurrencyService.transfer(from_user: user, to_user: receiver, amount: amount)
        "Successfully transferred #{amount} to @#{receiver_name}!"
      rescue CurrencyService::InsufficientFundsError
        "Transaction failed: Insufficient funds."
      end

    when /^!coffer invest (\d+) (.+)/
      amount = $1.to_i
      name = $2.strip
    invest_logic(user, amount, name, is_mod)
    else
      "Unknown coffer command. Use !coffer, !coffer transfer, or !coffer invest."
    end
  end

  private

def self.invest_logic(user, amount, name, is_mod)
    # Basic logic: Use a global interest rate from a setting or hardcoded for now
    # In your CMS, you could update a 'GlobalSetting.interest_rate'
    current_rate = 0.05 

    return "Minimum investment is 10." if amount < 10

existing_investment = Investment.active.find_by("lower(investment_name) = ?", name.downcase)
if existing_investment.nil?
      # If it doesn't exist, only mods can create it
      if is_mod
        create_new_investment(user, amount, name, current_rate)
      else
        "Investment '#{name}' doesn't exist yet. Ask a Moderator to create it!"
      end
    else
      # If it exists, anyone can buy into their own instance of it
      buy_into_investment(user, amount, existing_investment)
    end
  rescue CurrencyService::InsufficientFundsError
    "You don't have enough farthings to invest that much!"
  end

def self.create_new_investment(user, amount, name, rate)
    ActiveRecord::Base.transaction do
      CurrencyService.update_balance(user: user, amount: -amount, type: 'investment_creation', metadata: { name: name })
      Investment.create!(user: user, amount: amount, interest_rate: rate, investment_name: name)
    end
    "New public offering! '#{name}' established with #{amount} farthings!"
  end

  def self.buy_into_investment(user, amount, template)
    ActiveRecord::Base.transaction do
      CurrencyService.update_balance(user: user, amount: -amount, type: 'investment_buy_in', metadata: { name: template.investment_name })
      # We create a NEW investment record for THIS user, using the template's name and rate
      Investment.create!(user: user, amount: amount, interest_rate: template.interest_rate, investment_name: template.investment_name)
    end
    "You bought into '#{template.investment_name}' with #{amount} farthings!"
  end

end