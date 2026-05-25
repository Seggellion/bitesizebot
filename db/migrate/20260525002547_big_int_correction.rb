class BigIntCorrection < ActiveRecord::Migration[8.0]
def up
    change_column :investments, :amount, :bigint
  end

  def down
    change_column :investments, :amount, :integer
  end
end
