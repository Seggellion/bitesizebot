class HomeController < ApplicationController
  include SkillOfTheDayConcern

    def index
        @posts = Post.all
        @services = Service.all
        @homepage_services = Service.joins(:category).where(categories: { name: 'home-page' })
        @contact_message = ContactMessage.new
        @testimonials = Testimonial.by_category_name('home-page')
        @sections = Section.all
        @events = Event.order(created_at: :desc).limit(4)
    end

    def news
        @posts =  Post.joins(:category).where(categories: {slug: "news"}).order(created_at: :desc)
    render "pages/news"
    end

end