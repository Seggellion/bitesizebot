module Admin
    class TickersController < Admin::ApplicationController
  # Ensure you have a method in ApplicationController to verify admin status
  before_action :authenticate_admin!
  before_action :set_ticker, only: %i[show edit update destroy]


  # GET /admin/tickers
  def index
    @tickers = Ticker.all.order(name: :asc)
    
    # Aggregated data for the dashboard "Quick Stats" cards
    @total_market_cap = Ticker.sum("current_price * liquidity")
    @active_investments_count = Investment.where(status: :active).count
    @market_volatility = Ticker.average("ABS(current_price - previous_price)").to_f
  end

  # GET /admin/tickers/:id
  def show
    # @ticker is set by before_action
    # Fetching history limited to 100 for performance
    @price_history = @ticker.price_histories.order(created_at: :desc).limit(100)
  end

  # GET /admin/tickers/new
  def new
    @ticker = Ticker.new
  end

  # POST /admin/tickers
  def create
    @ticker = Ticker.new(ticker_params)

    if @ticker.save
      redirect_to admin_tickers_path, notice: "Ticker '#{@ticker.name}' was successfully initialized."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/tickers/:id/edit
  def edit
  end

  # PATCH/PUT /admin/tickers/:id
  def update
    if @ticker.update(ticker_params)
      redirect_to admin_ticker_path(@ticker), notice: "Ticker parameters updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/tickers/:id
  def destroy
    @ticker.destroy
    redirect_to admin_tickers_path, notice: "Ticker and all associated history were purged.", status: :see_other
  end

  private

  def set_ticker
    @ticker = Ticker.find(params[:id])
  end

  # Strong parameters for the new/edit form
  def ticker_params
    params.require(:ticker).permit(
      :name, 
      :current_price, 
      :previous_price, 
      :description, 
      :liquidity, 
        :symbol, 
        :momentum, 
      :max_liquidity, 
      :buy_pressure, 
      :sell_pressure
    )
  end

  # Example of a simple admin check
  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied. High-clearance personnel only."
    end
  end

    end

end