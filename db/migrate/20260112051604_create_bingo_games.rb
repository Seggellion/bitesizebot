class CreateBingoGames < ActiveRecord::Migration[8.0]
def change
    create_table :bingo_games do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.string :status, default: 'pending' # pending, active, completed
      t.integer :size, default: 5 # For a 5x5 grid
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end


    # The pool of phrases for the game
    create_table :bingo_items do |t|
      t.references :bingo_game, null: false, foreign_key: true
      t.string :content # e.g., "Muted on mic", "Technical difficulty"
      t.timestamps
    end

    # The viewer's individual card
    create_table :bingo_cards do |t|
      t.references :bingo_game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true # The Viewer
      t.timestamps
    end

    # The specific squares on a viewer's card
    create_table :bingo_cells do |t|
      t.references :bingo_card, null: false, foreign_key: true
      t.references :bingo_item, null: false, foreign_key: true
      t.integer :row_index # 0-4
      t.integer :column_index # 0-4
      t.boolean :is_marked, default: false
      t.timestamps
    end

  end
end

