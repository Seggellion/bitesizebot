require "test_helper"

class UserGiveawayEligibilityTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "winner remains ineligible during the three month cooldown" do
    travel_to Time.zone.local(2026, 6, 13, 12) do
      user = User.create!(uid: "recent-winner")
      create_win(user, drawn_at: 2.months.ago)

      assert_includes User.recent_winners, user
      assert user.won_recently?
    end
  end

  test "winner becomes eligible after the three month cooldown" do
    travel_to Time.zone.local(2026, 6, 13, 12) do
      user = User.create!(uid: "expired-winner")
      giveaway = create_win(user, drawn_at: 4.months.ago)
      giveaway.update_column(:updated_at, Time.current)

      assert_not_includes User.recent_winners, user
      assert_not user.won_recently?
    end
  end

  private

  def create_win(user, drawn_at:)
    Giveaway.create!(
      title: "Eligibility test",
      status: :completed,
      winner: user,
      drawn_at: drawn_at
    )
  end
end