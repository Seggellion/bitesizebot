class CreateMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :media do |t|
      t.string  :file
      t.text    :meta_description
      t.text    :meta_keywords
      t.boolean :approved
      t.boolean :screenshot_of_week
      t.string  :category
      t.boolean :staff, default: false

      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
