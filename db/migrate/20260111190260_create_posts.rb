class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string  :title
      t.text    :content
      t.boolean :published
      t.integer :views
      t.boolean :trashed

      t.references :user, foreign_key: true
      t.references :category, foreign_key: true

      t.timestamps
    end
  end
end
