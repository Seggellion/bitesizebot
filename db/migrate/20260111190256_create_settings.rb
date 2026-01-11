class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key
      t.text   :value
      t.string :group
      t.string :setting_type

      t.timestamps
    end
  end
end
