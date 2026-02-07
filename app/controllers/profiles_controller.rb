class ProfilesController < ApplicationController
  before_action :authenticate_user! # Assuming Devise or similar

  def show
    @user = current_user
    @ledger_entries = @user.ledger_entries.order(created_at: :desc).limit(50)
    @investments = @user.investments.includes(:ticker)
    @giveaway_entries = @user.giveaway_entries.order(created_at: :desc)
    
    # Quick Stats for the "Analyst" feel
    @total_balance = @user.ledger_entries.sum(:amount)
    @active_investments = @investments.where(status: :active).count
      render "pages/profile"

  end
end