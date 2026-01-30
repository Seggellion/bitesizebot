class AddTickerToInvestment < ActiveRecord::Migration[8.0]
  def change

add_reference :investments, :ticker, null: true, foreign_key: true

    # 2. Assign existing records to the first Ticker
    # We use 'up' logic or direct SQL to ensure it runs during migration
    reversible do |dir|
      dir.up do
        first_ticker_id = Ticker.first&.id
        if first_ticker_id
          Investment.update_all(ticker_id: first_ticker_id)
        end
      end
    end

    # 3. Now change the column to NOT NULL
    change_column_null :investments, :ticker_id, false

  end
end
