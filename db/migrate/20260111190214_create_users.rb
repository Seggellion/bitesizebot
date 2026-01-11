class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string  :email,    null: false
      t.string  :uid,      null: false
      t.string  :provider
      t.string  :username
      t.integer :user_type
      t.string  :first_name
      t.string  :last_name
      t.string  :avatar
      t.string  :ip_address
      t.string  :country
      t.datetime :last_login

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :uid,   unique: true
  end
end
