class CreatePendingActionVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_action_votes do |t|
      t.references :pending_action, null: false, foreign_key: true
      t.references :moderator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :pending_action_votes,
              [:pending_action_id, :moderator_id],
              unique: true,
              name: "index_pending_action_votes_on_action_and_moderator"
  end
end
