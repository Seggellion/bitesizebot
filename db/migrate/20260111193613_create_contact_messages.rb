class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string   :first_name
      t.string   :last_name
      t.string   :email
      t.string   :phone
      t.text     :properties
      t.string   :subject
      t.text     :body
      t.datetime :read_at
      t.string   :ip_address
      t.string   :country_code

      t.timestamps
    end
  end
end
