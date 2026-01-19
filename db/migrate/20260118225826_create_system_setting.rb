class CreateSystemSetting < ActiveRecord::Migration[8.0]
  def change
  
    create_table :system_settings do |t|
      t.string  :broadcaster_uid
      t.string :bot_uid
      t.boolean :bot_enabled, default: false, null: false

      # This column ensures we only ever have one row
      t.integer :singleton_guard, default: 0, null: false

      t.timestamps
    end

    # Create a unique index on the guard.
    # If any code tries to insert a second row with '0', the DB will reject it.
    add_index :system_settings, :singleton_guard, unique: true
  
  end
end
