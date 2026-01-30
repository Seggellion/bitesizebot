class HomeController < ApplicationController
before_action :authenticate_user!

    def index
@tickers = Ticker.all
  # Default to the first ticker or a params-based selection
  @active_ticker = params[:symbol] ? Ticker.find_by(symbol: params[:symbol]) : @tickers.first
  
  @user = current_user
  @investments = @user.investments.includes(:ticker)
  
  # Calculate Portfolio Stats
  @total_invested = @investments.sum(:amount)
  @current_value = @investments.sum { |inv| 
    # Logic: (Current Price / Purchase Price) * Original Amount
    ticker = Ticker.find_by(name: inv.investment_name)
    ticker ? (ticker.current_price / inv.purchase_price) * inv.amount : inv.amount
  }
  
@recent_ledger = LedgerEntry.where(entry_type: LedgerEntry::TRADING_TYPES)
                              .order(created_at: :desc)
                              .limit(15)

            render "pages/home"

    end

    def news
        @posts =  Post.joins(:category).where(categories: {slug: "news"}).order(created_at: :desc)
    render "pages/news"
    end

end