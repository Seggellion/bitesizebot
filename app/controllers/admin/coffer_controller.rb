module Admin
    class CofferController < Admin::ApplicationController
    def index
   @total_supply = User.sum(:wallet)

    @total_market_cap = Investment.active.all.sum(&:current_value)
    @tickers = Ticker.all.order(name: :asc)
    @top_holders = User.order(wallet: :desc).limit(10)
    
    @recent_transactions = LedgerEntry.includes(:user).order(created_at: :desc).limit(20)
    
    # Growth Metrics
    @points_earned_24h = LedgerEntry.where("amount > 0 AND created_at > ?", 24.hours.ago).sum(:amount)
    @points_spent_24h = LedgerEntry.where("amount < 0 AND created_at > ?", 24.hours.ago).sum(:amount).abs
    end

    def mass_grant
      amount = params[:amount].to_i
      minutes = params[:minutes].to_i

      if amount <= 0
        redirect_to admin_coffer_index_path, alert: "Please enter a valid amount."
        return
      end

      # Find users updated within the last X minutes
      active_users = User.where("updated_at >= ?", minutes.minutes.ago)

      if active_users.any?
        active_users.find_each do |user|
          CurrencyService.update_balance(
            user: user,
            amount: amount,
            type: 'mass_grant',
            metadata: { 
              admin_id: current_user.id, 
              timeframe_minutes: minutes,
              reason: "Active in last #{minutes}m"
            }
          )
        end
        redirect_to admin_coffer_index_path, notice: "Successfully granted #{amount} to #{active_users.count} active users."
      else
        redirect_to admin_coffer_index_path, alert: "No active users found in the last #{minutes} minutes."
      end
    end
  

def inject_currency
    
    user = User.find_by(username: params[:username])
    amount = params[:amount].to_i

    if user && amount != 0
      CurrencyService.update_balance(
        user: user,
        amount: amount,
        type: 'admin_grant',
        metadata: { admin_id: current_user.id, reason: params[:reason] }
      )
      flash[:notice] = "Successfully sent #{amount} to #{user.username}."
    else
      flash[:error] = "User not found or invalid amount."
    end

    redirect_to admin_coffer_index_path
  end

end
end