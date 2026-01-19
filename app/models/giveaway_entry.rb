# app/models/giveaway_entry.rb
class GiveawayEntry < ApplicationRecord
  belongs_to :giveaway
  belongs_to :user

validate :user_must_be_follower, on: :create

  # Every time someone joins or adds tickets, update the Admin dashboard
  after_create_commit :broadcast_entry
  after_update_commit :broadcast_entry

  private

def user_must_be_follower

    broadcaster_id = User.broadcaster.uid

    unless TwitchWebsocketListener.is_follower?(broadcaster_id, user.uid)
      errors.add(:base, "I'm sorry, the grand elf said only friends of the Shire (followers) may enter this party!")
    end
  end

  def broadcast_entry
    broadcast_prepend_to "giveaway_#{giveaway_id}_entries", 
                         target: "giveaway_entries_list", 
                         partial: "admin/giveaway_entries/giveaway_entry", 
                         locals: { giveaway_entry: self }
  end
end