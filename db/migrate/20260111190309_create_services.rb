class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string  :title, null: false
      t.text    :content
      t.string  :slug
      t.boolean :published

      t.references :category, foreign_key: true

      t.text :meta_description
      t.text :meta_keywords

      t.timestamps
    end
  end
end
