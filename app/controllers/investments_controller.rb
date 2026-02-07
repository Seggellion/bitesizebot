class InvestmentsController < ApplicationController
  def sell_all
    @investment = current_user.investments.find_by(ticker_id: params[:ticker_id], status: :active)

    if @investment
      ActiveRecord::Base.transaction do
        # 1. Mark as pending so the user can't interact with it
        @investment.pending_sale!

        # 2. Add Sell Pressure immediately
        # This ensures the price drops in the next tick calculation *before* they get paid
        ticker = @investment.ticker
        ticker.with_lock do
          # We add the share amount directly to sell_pressure
          # (Adjust logic if your pressure scale is different)
          ticker.sell_pressure += @investment.amount
          ticker.save!
        end
      end

      redirect_back fallback_location: root_path, notice: "Sell order queued! waiting for next market tick..."
    else
      redirect_back fallback_location: root_path, alert: "No active investment found."
    end
  end
end