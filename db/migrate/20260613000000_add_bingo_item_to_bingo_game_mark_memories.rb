class AddBingoItemToBingoGameMarkMemories < ActiveRecord::Migration[8.0]
  def up
    add_reference :bingo_game_mark_memories, :bingo_item, foreign_key: true

    execute <<~SQL
      UPDATE bingo_game_mark_memories memories
      SET bingo_item_id = matches.bingo_item_id
      FROM (
        SELECT cards.bingo_game_id, cells.coordinate, MIN(cells.bingo_item_id) AS bingo_item_id
        FROM bingo_cells cells
        INNER JOIN bingo_cards cards ON cards.id = cells.bingo_card_id
        GROUP BY cards.bingo_game_id, cells.coordinate
        HAVING COUNT(DISTINCT cells.bingo_item_id) = 1
      ) matches
      WHERE memories.bingo_game_id = matches.bingo_game_id
        AND memories.coordinate = matches.coordinate
        AND memories.bingo_item_id IS NULL
    SQL

    clear_duplicate_item_backfills

    add_index :bingo_game_mark_memories,
              [:bingo_game_id, :bingo_item_id],
              unique: true,
              name: "index_bingo_game_mark_memories_on_game_and_item"
  end

  def down
    remove_index :bingo_game_mark_memories,
                 name: "index_bingo_game_mark_memories_on_game_and_item"
    remove_reference :bingo_game_mark_memories, :bingo_item, foreign_key: true
  end

  private

  def clear_duplicate_item_backfills(table_name = :bingo_game_mark_memories)
    table = connection.quote_table_name(table_name)

    execute <<~SQL
      WITH ranked_memories AS (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY bingo_game_id, bingo_item_id
                 ORDER BY id
               ) AS item_rank
        FROM #{table}
        WHERE bingo_item_id IS NOT NULL
      )
      UPDATE #{table} memories
      SET bingo_item_id = NULL
      FROM ranked_memories
      WHERE memories.id = ranked_memories.id
        AND ranked_memories.item_rank > 1
    SQL
  end
end
