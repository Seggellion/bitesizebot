class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages do |t|
      t.string  :title, null: false
      t.text    :content
      t.string  :slug
      t.boolean :published
      t.string  :template

      t.references :user,     foreign_key: true
      t.references :category, foreign_key: true

      t.text :meta_description
      t.text :meta_keywords

      t.timestamps
    end
  end
end
