class TradePressure < ActiveRecord::Migration[8.0]
  def change

    add_column :tickers, :buy_pressure, :float, default: 0.0
    add_column :tickers, :sell_pressure, :float, default: 0.0

    add_column :tickers, :description, :text
    add_column :tickers, :symbol, :string

    add_column :tickers, :liquidity, :float, default: 1_000.0
    add_column :tickers, :max_liquidity, :float, default: 1_000.0

    add_column :price_histories, :volume, :float, default: 0.0
    add_column :price_histories, :open, :float
    add_column :price_histories, :high, :float
    add_column :price_histories, :low, :float
    add_column :price_histories, :close, :float

  end
end
