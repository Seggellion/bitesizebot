class CreateDownloads < ActiveRecord::Migration[8.0]
  def change
    create_table :downloads do |t|
      t.string  :title, null: false
      t.text    :description
      t.string  :link_url
      t.string  :link_text
      t.integer :order, default: 0

      t.references :category, foreign_key: true

      t.timestamps
    end
  end
end
