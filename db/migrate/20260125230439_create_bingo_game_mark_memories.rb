class CreateBingoGameMarkMemories < ActiveRecord::Migration[8.0]
  def change
  
     create_table :bingo_game_mark_memories do |t|
      t.references :bingo_game, null: false, foreign_key: true
      t.string :coordinate, null: false
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    add_index :bingo_game_mark_memories, [:bingo_game_id, :coordinate], unique: true
  
  end
end
