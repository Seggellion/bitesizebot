class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    
    # 1. Ticker Selection (with fallback)
    @tickers = Ticker.all.sort_by do |t|
      prev = t.previous_price.to_f > 0 ? t.previous_price.to_f : 1.0
      (t.current_price.to_f - t.previous_price.to_f) / prev
    end.reverse

    @active_ticker = if params[:symbol]
                Ticker.find_by(symbol: params[:symbol].upcase)
              else
                @tickers.first
              end

    # Eager load for performance
    all_investments = @user.investments.includes(:ticker)

@recent_ledger_entries = LedgerEntry
  .where(entry_type: LedgerEntry::TRADING_TYPES)
  .where("metadata->>'ticker' = ?", @active_ticker.symbol)
  .order(created_at: :desc)
  .limit(15)

  


  # 2. ACTIVE HOLDINGS
  @active_holdings = all_investments.select(&:active?)
  @active_ticker_ids = @active_holdings.map(&:ticker_id).to_set

  # 3. PENDING ORDERS (Separate logic for Buy vs Sell)
  @pending_orders = all_investments.select { |inv| inv.pending_purchase? || inv.pending_sale? }

  # 4. TRADE HISTORY
  @trade_history = all_investments.select(&:redeemed?).sort_by(&:updated_at).reverse

    # 5. PORTFOLIO HEADER STATS
    @total_invested = @active_holdings.sum(&:amount)
   @current_value  = @active_holdings.sum(&:current_value) 
    @portfolio_roi  = @total_invested > 0 ? ((@current_value - @total_invested) / @total_invested.to_f) * 100 : 0

    # 6. GLOBAL LEDGER
    @recent_ledger = LedgerEntry.where(entry_type: LedgerEntry::TRADING_TYPES)
                                .order(created_at: :desc)
                                .limit(15)

    render "pages/home"
  end

  def news
    @posts = Post.joins(:category).where(categories: { slug: "news" }).order(created_at: :desc)
    render "pages/news"
  end
end