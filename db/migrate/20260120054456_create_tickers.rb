class CreateTickers < ActiveRecord::Migration[8.0]
  def change
    create_table :tickers do |t|
      t.string :name
      t.decimal :current_price
      t.decimal :previous_price

      t.timestamps
    end
  end
end
