class ChangeDefaultStatus < ActiveRecord::Migration[8.0]
  def change
    change_column_default :bingo_games, :status, from: "pending", to: "invite"
  end
end
