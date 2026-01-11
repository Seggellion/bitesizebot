class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :content

      t.references :user, foreign_key: true
      t.string  :commentable_type
      t.bigint  :commentable_id

      t.timestamps
    end

    add_index :comments, [:commentable_type, :commentable_id]
  end
end
