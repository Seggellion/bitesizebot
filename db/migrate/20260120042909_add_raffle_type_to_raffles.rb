class AddRaffleTypeToRaffles < ActiveRecord::Migration[8.0]
  def change
    add_column :raffles, :raffle_type, :string
  end
end
