class CreateMenuItems < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_items do |t|
      t.string  :title
      t.string  :url
      t.integer :position
      t.integer :parent_id

      t.integer :item_type, null: false, default: 0
      t.integer :item_id

      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
