module Admin
    class CofferController < Admin::ApplicationController
    def index
   @total_supply = User.sum(:wallet)
    @active_investments = Investment.active
    @investment_liability = @active_investments.map(&:current_value).sum
    
    @top_holders = User.order(wallet: :desc).limit(10)
    
    @recent_transactions = LedgerEntry.includes(:user).order(created_at: :desc).limit(20)
    
    # Growth Metrics
    @points_earned_24h = LedgerEntry.where("amount > 0 AND created_at > ?", 24.hours.ago).sum(:amount)
    @points_spent_24h = LedgerEntry.where("amount < 0 AND created_at > ?", 24.hours.ago).sum(:amount).abs
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

    redirect_to admin_coffer_path
  end

end
end