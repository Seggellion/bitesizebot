class CustomCommand < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :response, presence: true
  
  # Ensure name is always lowercase for easier lookup
  before_save { self.name = name.downcase.strip }
  
  # Cache busting: Clear the cache for this command whenever it's saved or deleted
  after_commit :flush_cache

  def self.cached_find(command_name)
    Rails.cache.fetch("twitch_cmd/#{command_name.downcase}") do
      find_by(name: command_name.downcase)
    end
  end

  private

  def flush_cache
    Rails.cache.delete("twitch_cmd/#{name_previously_was}") if name_previously_changed?
    Rails.cache.delete("twitch_cmd/#{name}")
  end
end