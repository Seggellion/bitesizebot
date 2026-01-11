class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections do |t|
      t.string  :name, null: false
      t.string  :template, null: false
      t.integer :animation_speed
      t.integer :position
      t.string  :subtitle
      t.text    :body

      t.timestamps
    end
  end
end
