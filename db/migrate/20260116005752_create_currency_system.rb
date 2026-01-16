class CreateCurrencySystem < ActiveRecord::Migration[8.0]
  def change
  create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false
      t.decimal :interest_rate, precision: 5, scale: 4, default: 0.01
      t.integer :status, default: 0 # 0: active, 1: redeemed
      t.string :investment_name
      t.timestamps
    end

  add_column :users, :wallet, :bigint, default: 0, null: false

    create_table :ledger_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false # Positive for credit, negative for debit
      t.string :entry_type, null: false # e.g., 'gift', 'minigame', 'bingo_purchase'
      t.jsonb :metadata, default: {} # Store info like { "from_user_id": 123 }

      t.timestamps
    end

    add_index :ledger_entries, :entry_type
  end
end
