class CreateRaffles < ActiveRecord::Migration[8.0]
  def change
  
  # rails generate migration CreateRaffles
create_table :raffles do |t|
  t.references :host, null: false, foreign_key: { to_table: :users }
  t.string :status, default: 'active' # active, ended
  t.integer :max_participants, default: 500
  t.integer :prize_amount, default: 0
  t.integer :winner_id
  t.datetime :ended_at
  t.timestamps
end

# rails generate migration CreateRaffleEntries
create_table :raffle_entries do |t|
  t.references :raffle, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.timestamps
end

add_index :raffle_entries, [:raffle_id, :user_id], unique: true
  
  end
end
