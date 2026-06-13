require "test_helper"

class GiveawayOverlayTest < ActiveSupport::TestCase
  test "drawing a ticket giveaway broadcasts the winner to the bingo overlay stream" do
    winner = User.create!(uid: "overlay-giveaway-winner", username: "shirewinner", user_type: :regular)
    giveaway = Giveaway.create!(title: "Overlay Giveaway", giveaway_type: :ticket, status: :closed)
    giveaway.giveaway_entries.create!(user: winner, tickets_count: 1)
    broadcast = nil

    giveaway.stub(:announce_winner_to_twitch, nil) do
      giveaway.stub(:broadcast_prepend_to, ->(*args, **kwargs) { broadcast = [args, kwargs] }) do
        assert_equal winner, giveaway.draw_winner!
      end
    end

    assert_equal ["active_game_overlay"], broadcast.first
    assert_equal "overlay_notifications", broadcast.last[:target]
    assert_equal "admin/giveaways/overlay_winner_notification", broadcast.last[:partial]
    assert_equal winner, broadcast.last.dig(:locals, :winner)
  end
end
