class EnsureBingoGameMarkMemoriesBingoItemReference < ActiveRecord::Migration[8.0]
  def up
    add_bingo_item_column unless column_exists?(:bingo_game_mark_memories, :bingo_item_id)

    backfill_bingo_item_ids
    clear_duplicate_item_backfills
    clear_invalid_item_references

    add_bingo_item_index unless index_exists?(:bingo_game_mark_memories, :bingo_item_id)
    add_game_item_index unless index_exists?(:bingo_game_mark_memories,
                                             [:bingo_game_id, :bingo_item_id],
                                             name: "index_bingo_game_mark_memories_on_game_and_item")
    add_bingo_item_foreign_key unless foreign_key_exists?(:bingo_game_mark_memories, :bingo_items)
  end

  def down
    say "Leaving bingo_game_mark_memories.bingo_item_id in place to avoid data loss"
  end

  private

  def add_bingo_item_column
    add_reference :bingo_game_mark_memories,
                  :bingo_item,
                  index: false,
                  foreign_key: false
  end

  def backfill_bingo_item_ids
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
  end

  def clear_duplicate_item_backfills
    execute <<~SQL
      WITH ranked_memories AS (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY bingo_game_id, bingo_item_id
                 ORDER BY id
               ) AS item_rank
        FROM bingo_game_mark_memories
        WHERE bingo_item_id IS NOT NULL
      )
      UPDATE bingo_game_mark_memories memories
      SET bingo_item_id = NULL
      FROM ranked_memories
      WHERE memories.id = ranked_memories.id
        AND ranked_memories.item_rank > 1
    SQL
  end

  def clear_invalid_item_references
    execute <<~SQL
      UPDATE bingo_game_mark_memories memories
      SET bingo_item_id = NULL
      WHERE bingo_item_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM bingo_items items
          WHERE items.id = memories.bingo_item_id
        )
    SQL
  end

  def add_bingo_item_index
    add_index :bingo_game_mark_memories, :bingo_item_id
  end

  def add_game_item_index
    add_index :bingo_game_mark_memories,
              [:bingo_game_id, :bingo_item_id],
              unique: true,
              name: "index_bingo_game_mark_memories_on_game_and_item"
  end

  def add_bingo_item_foreign_key
    add_foreign_key :bingo_game_mark_memories, :bingo_items
  end
end
