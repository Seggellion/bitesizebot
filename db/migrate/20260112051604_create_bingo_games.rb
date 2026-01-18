class CreateBingoGames < ActiveRecord::Migration[8.0]
  def change
    create_table :bingo_games do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.references :winner, null: true, foreign_key: { to_table: :users }

      t.string :title
      t.string :status, default: 'pending'
      t.integer :size, default: 5
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end

    # Items are now independent "Global" or "User-owned" phrases
    create_table :bingo_items do |t|
      t.integer :row_number
      t.string :column_letter
      t.string :content
      t.timestamps
    end

    # JOIN TABLE: Links items to specific games
    create_table :bingo_game_items do |t|
      t.references :bingo_game, null: false, foreign_key: true
      t.references :bingo_item, null: false, foreign_key: true
      t.timestamps
    end

    create_table :bingo_cards do |t|
      t.references :bingo_game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :replacement_count, default: 0
      t.timestamps
    end

    create_table :bingo_cells do |t|
      t.references :bingo_card, null: false, foreign_key: true
      t.references :bingo_item, null: false, foreign_key: true
      t.string :coordinate
      t.boolean :is_marked, default: false
      t.timestamps
    end
  end
end
