class CreateCustomCommands < ActiveRecord::Migration[8.0]
  def change
  
  create_table :custom_commands do |t|
      t.string :name, null: false
      t.text :response, null: false
      t.string :author, null: false
      t.string :permission_level, default: 'everyone'

      t.timestamps
    end
    add_index :custom_commands, :name, unique: true
  
  end
end
