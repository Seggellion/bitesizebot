class CreatePendingActions < ActiveRecord::Migration[8.0]
  def change
  
    create_table :pending_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target, polymorphic: true, null: false # e.g., BingoCell
      t.string :action_type # e.g., "mark_cell"
      t.string :status, default: "pending" # pending, approved, denied
      t.text :metadata # To store extra info like the Twitch command used
      t.timestamps
    end

  end
end
