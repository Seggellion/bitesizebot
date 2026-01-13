class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string  :uid,      null: false
      t.string  :provider
      t.string  :username
      t.integer :user_type
      t.integer :karma,     default: 0
      t.integer :fame,      default: 0
      t.string  :first_name
      t.string  :last_name
      t.string  :avatar
      t.string  :ip_address
      t.string  :country
      t.string  :twitch_access_token
      t.string  :twitch_refresh_token
      t.datetime :last_login

      t.timestamps
    end

    add_index :users, :uid,   unique: true
  end
end
