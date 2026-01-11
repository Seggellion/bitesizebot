class CreateTestimonials < ActiveRecord::Migration[8.0]
  def change
    create_table :testimonials do |t|
      t.string :title, null: false
      t.text   :content

      t.references :category, foreign_key: true

      t.timestamps
    end
  end
end
