# app/models/raffle.rb
class Raffle < ApplicationRecord
  belongs_to :host, class_name: 'User'
  has_many :raffle_entries, dependent: :destroy
  has_many :users, through: :raffle_entries

# app/models/raffle.rb
def select_and_payout_winners!
  entrants = self.raffle_entries.map(&:user).shuffle
  return [] if entrants.empty?

  # Determine number of winners
  num_winners = if self.raffle_type == '-s'
                  1
                else
                  # Pick between 2 and 4, but don't exceed the number of entrants
                  [rand(2..4), entrants.size].min
                end

  winners = entrants.sample(num_winners)
  payout_per_person = (self.prize_amount.to_f / winners.size).floor

  # Payout logic
  Transaction.transaction do
    winners.each do |winner|
      winner.ledger_entries.create!(
        amount: payout_per_person,
        entry_type: 'raffle_win',
        metadata: { raffle_id: self.id }
      )
      winner.increment!(:wallet, payout_per_person)
    end
  end

  winners
end

end