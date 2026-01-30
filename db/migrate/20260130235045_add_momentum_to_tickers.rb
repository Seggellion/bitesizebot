class AddMomentumToTickers < ActiveRecord::Migration[8.0]
  def change
    add_column :tickers, :momentum, :float
  end
end
