class CreateBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :blocks do |t|
      t.references :section, null: false, foreign_key: true
      t.integer :block_type, null: false
      t.text    :content
      t.string  :block_link
      t.integer :position

      t.timestamps
    end
  end
end
