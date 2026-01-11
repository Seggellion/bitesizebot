# app/services/achievements/award_skill_max.rb
module Achievements
  class AwardSkillMax
    def self.call(shard_user_skill)
      new(shard_user_skill).call
    end

    def initialize(sus)
      @sus = sus
    end

    def call
      return unless @sus.value.to_f >= 100.0
      su = @sus.shard_user
      return unless su

      name = "Grandmaster: #{skill_name}"

      Achievement.find_or_create_by!(
        user_id:  fetch(su, :user_id),
        shard_id: fetch(su, :shard_id),
        name:     name
      ) do |a|
        a.description   = "Reached 100.0 in #{skill_name}"
        a.reward_points = 100
        a.type          = "SkillMaxAchievement"
        a.icon          = "icons/achievements/grandmaster.png"
        a.city_name     = fetch(su, :city_name)
        a.owner_uuid    = fetch(su, :owner_uuid)
      end
    end

    private

    def skill_name
      @sus.skill.try(:name) || "Unknown Skill"
    end

    def fetch(obj, attr)
      obj.respond_to?(attr) ? obj.public_send(attr) : nil
    end
  end
end
