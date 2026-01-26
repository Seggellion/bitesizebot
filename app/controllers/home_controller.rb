class HomeController < ApplicationController

    def index

            render "pages/home"

    end

    def news
        @posts =  Post.joins(:category).where(categories: {slug: "news"}).order(created_at: :desc)
    render "pages/news"
    end

end