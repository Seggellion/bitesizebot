class SystemSetting < ApplicationRecord
  validates :singleton_guard, presence: true, inclusion: { in: [0] }
  before_destroy { throw(:abort) }

  def self.instance
    # Wrapping this in .uncached ensures Rails doesn't use 
    # the "Query Cache" from the start of the process.
    unscoped.uncached do
      first_or_create!(singleton_guard: 0)
    end
  end

  def self.broadcaster_uid
    # We reload the instance to get fresh data from the DB disk
    instance.reload.broadcaster_uid
  end

    def self.bot_uid
    # We reload the instance to get fresh data from the DB disk
    instance.reload.bot_uid
  end


  def self.bot_enabled?
    # We reload the instance to get fresh data from the DB disk
    instance.reload.bot_enabled
  end
end