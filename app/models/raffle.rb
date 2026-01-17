# app/models/raffle.rb
class Raffle < ApplicationRecord
  belongs_to :host, class_name: 'User'
  has_many :raffle_entries, dependent: :destroy
  has_many :users, through: :raffle_entries

  def select_and_payout_winners!
    return [] if users.empty?

    # ✅ Random 2–4 winners
    winner_count = rand(2..4)
    potential_winners = users.distinct.sample(winner_count)
    
    # ✅ Even split of points
    split_prize = (prize_amount.to_f / potential_winners.size).floor

    potential_winners.each do |winner|
      LedgerEntry.create!(
        user: winner,
        amount: split_prize,
        entry_type: 'raffle_win',
        metadata: { raffle_id: id, total_pool: prize_amount }
      )
      winner.increment!(:wallet, split_prize)
    end

    update!(status: 'ended', ended_at: Time.current)
    potential_winners
  end
end