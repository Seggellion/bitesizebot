class CreateAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :achievements do |t|
      t.string  :name, null: false
      t.string  :description
      t.string  :icon
      t.string  :achievement_type
      t.integer :reward_points, default: 0
      t.string  :owner_uuid

      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :achievements, [:user_id, :name], unique: true
  end
end
