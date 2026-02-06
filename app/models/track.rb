class Track < ApplicationRecord
  enum track_type: { music: 'music', advertisement: 'advertisement' }

  # High-performance random selector
  def self.pick_random(type:)
    # Get IDs of the 500 least recently played tracks of this type
    candidate_ids = where(track_type: type)
                    .order(last_played_at: :asc)
                    .limit(500)
                    .pluck(:id)
    
    find(candidate_ids.sample)
  end
end