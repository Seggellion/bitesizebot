class HomeController < ApplicationController
before_action :authenticate_user!
def index
  @user = current_user
  
  # Eager load tickers to prevent N+1 queries
  all_investments = @user.investments.includes(:ticker)

  # 1. Filter ACTIVE Holdings and apply "Twitch Logic" math
  @active_holdings = all_investments.where(status: :active).map do |inv|
    # Twitch Logic: Amount is Farthings Spent. 
    # Shares = Farthings / Purchase Price
    cost_basis    = inv.amount.to_f
    share_count   = cost_basis / inv.purchase_price
    current_value = share_count * inv.ticker.current_price
    
    profit_loss   = current_value - cost_basis
    roi_percent   = (profit_loss / (cost_basis > 0 ? cost_basis : 1)) * 100

    # Define virtual helper methods for the view
    inv.define_singleton_method(:shares) { share_count }
    inv.define_singleton_method(:market_value) { current_value }
    inv.define_singleton_method(:pl_dollars) { profit_loss }
    inv.define_singleton_method(:pl_percent) { roi_percent }
    inv
  end

  @active_ticker_ids = @active_holdings.map(&:ticker_id).to_set

  # 2. Sort Tickers by Highest Percentage Change
  @tickers = Ticker.all.sort_by do |t|
    prev = t.previous_price.to_f > 0 ? t.previous_price.to_f : 1
    (t.current_price.to_f - t.previous_price.to_f) / prev
  end.reverse # Highest gainers first

  @active_ticker = params[:symbol] ? Ticker.find_by(symbol: params[:symbol]) : @tickers.first

  # 3. Portfolio Header Stats (Active Only)
  
  @total_invested = @active_holdings.sum { |inv| inv.amount } # Total farthings spent
  @current_value  = @active_holdings.sum(&:market_value)
  @portfolio_roi  = @total_invested > 0 ? ((@current_value - @total_invested) / @total_invested) * 100 : 0

  @recent_ledger = LedgerEntry.where(entry_type: LedgerEntry::TRADING_TYPES)
                              .order(created_at: :desc)
                              .limit(15)


@trade_history = all_investments.where.not(status: :active).order(updated_at: :desc).map do |trade|

  cost_basis = trade.amount.to_f
  shares = cost_basis / trade.purchase_price

  exit_value = shares * trade.ticker.current_price
  profit_loss = exit_value - cost_basis

  trade.define_singleton_method(:exit_value) { exit_value }
  trade.define_singleton_method(:total_profit) { profit_loss }
  trade
end


  render "pages/home"
end



    def news
        @posts =  Post.joins(:category).where(categories: {slug: "news"}).order(created_at: :desc)
    render "pages/news"
    end

end