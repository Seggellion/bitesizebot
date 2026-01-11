class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title
      t.text   :description
      t.string :location
      t.string :slug
      t.string :timezone
      t.datetime :start_time
      t.datetime :end_time

      t.references :user,     foreign_key: true
      t.references :category, foreign_key: true

      t.timestamps
    end
  end
end
