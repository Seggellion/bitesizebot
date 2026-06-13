require "test_helper"
require Rails.root.join("db/migrate/20260613000000_add_bingo_item_to_bingo_game_mark_memories")

class AddBingoItemToBingoGameMarkMemoriesTest < ActiveSupport::TestCase
  test "duplicate backfills preserve one item claim and clear later duplicates" do
    table_name = "temporary_bingo_mark_memories_#{Process.pid}"
    connection = ActiveRecord::Base.connection
    connection.create_table(table_name, temporary: true) do |table|
      table.bigint :bingo_game_id, null: false
      table.bigint :bingo_item_id
      table.string :coordinate, null: false
    end

    connection.execute <<~SQL
      INSERT INTO #{connection.quote_table_name(table_name)}
        (bingo_game_id, bingo_item_id, coordinate)
      VALUES
        (1, 10, 'B1'),
        (1, 10, 'B2'),
        (1, NULL, 'B3'),
        (2, 10, 'B1')
    SQL

    AddBingoItemToBingoGameMarkMemories.new.send(
      :clear_duplicate_item_backfills,
      table_name
    )
    connection.add_index(
      table_name,
      [:bingo_game_id, :bingo_item_id],
      unique: true,
      name: "index_temporary_bingo_memories_on_game_and_item"
    )

    rows = connection.select_all(<<~SQL).to_a
      SELECT bingo_game_id, bingo_item_id, coordinate
      FROM #{connection.quote_table_name(table_name)}
      ORDER BY bingo_game_id, coordinate
    SQL

    assert_equal 10, rows[0]["bingo_item_id"]
    assert_nil rows[1]["bingo_item_id"]
    assert_nil rows[2]["bingo_item_id"]
    assert_equal 10, rows[3]["bingo_item_id"]
  ensure
    connection&.drop_table(table_name, if_exists: true)
  end
end
