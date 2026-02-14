class InvestmentsController < ApplicationController

def create
  @ticker = Ticker.find(params[:ticker_id])
  amount = params[:amount].to_i

  if current_user.wallet < amount
    redirect_to root_path(symbol: @ticker.symbol), alert: "Insufficient farthings!" and return
  end

  if amount < 200
    redirect_to root_path(symbol: @ticker.symbol), alert: "Minimum investment is 200 farthings." and return
  end

  ActiveRecord::Base.transaction do
    # 1. Deduct the money immediately (so they can't spend it elsewhere)
    CurrencyService.update_balance(
      user: current_user, 
      amount: -amount, 
      type: 'stock_purchase_queued',
      metadata: { ticker: @ticker.symbol }
    )

    # 2. Create a pending purchase record
    # We store the 'amount' (cash), but purchase_price is nil/0 
    # because we don't know the future price yet!
    Investment.create!(
      user: current_user,
      ticker: @ticker,
      amount: amount,
      investment_name: @ticker.symbol,
      status: :pending_purchase
    )

    # 3. Add Buy Pressure immediately 
    # This ensures the price spikes in the next tick BEFORE the order fills
    @ticker.increment!(:buy_pressure, amount) 
  end

  redirect_to root_path(symbol: @ticker.symbol), notice: "Purchase queued! waiting for market tick..."
rescue => e
  redirect_to root_path(symbol: @ticker.symbol), alert: "Error: #{e.message}"
end

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