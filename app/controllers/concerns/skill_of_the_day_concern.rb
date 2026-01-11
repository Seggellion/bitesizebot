module SkillOfTheDayConcern
  extend ActiveSupport::Concern

  included do
    helper_method :skill_of_the_day, :skill_page
  end

  def skill_of_the_day   
    @skill_of_the_day ||= ::SkillOfTheDay.for   
    @skill_page ||= Page.find_by(slug: @skill_of_the_day.slug) if @skill_of_the_day&.respond_to?(:slug)
 byebug
    @skill_of_the_day
  end

  def skill_page
    @skill_page
  end
end
