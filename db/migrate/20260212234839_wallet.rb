class Wallet < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :wallet, :bigint

    # Change the amount on the ledger_entries table
    change_column :ledger_entries, :amount, :bigint
  end
end
