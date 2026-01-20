class AddPurchasePriceToInvestments < ActiveRecord::Migration[8.0]
  def change
    add_column :investments, :purchase_price, :decimal
  end
end
