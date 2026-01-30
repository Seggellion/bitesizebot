class HomeController < ApplicationController
before_action :authenticate_user!

    def index
@tickers = Ticker.all
    @user = current_user
    @top_investments = @user.investments.order(created_at: :desc).limit(5)

            render "pages/home"

    end

    def news
        @posts =  Post.joins(:category).where(categories: {slug: "news"}).order(created_at: :desc)
    render "pages/news"
    end

end