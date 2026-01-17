class CreateGiveaways < ActiveRecord::Migration[8.0]
  def change
  
  create_table :giveaways do |t|
      t.string :title
      t.integer :giveaway_type, default: 0 # 0: ticket, 1: bingo
      t.integer :status, default: 0        # 0: open, 1: closed, 2: completed
      t.integer :max_entries_per_user      # null for unlimited
      t.integer :min_karma, default: 0
      t.integer :min_fame, default: 0
      t.references :winner, foreign_key: { to_table: :users }
      t.datetime :drawn_at
      t.timestamps
    end

    create_table :giveaway_entries do |t|
      t.references :giveaway, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :tickets_count, default: 0
      t.timestamps
    end
    
    add_index :giveaway_entries, [:giveaway_id, :user_id], unique: true

  end
end
