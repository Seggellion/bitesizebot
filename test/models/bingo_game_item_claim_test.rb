require "test_helper"

class BingoGameItemClaimTest < ActiveSupport::TestCase
  setup do
    Setting.set("current-theme", "Hobbit")
    @host = create_user("claim-host")
    @admin = create_user("claim-admin", :admin)
    @player_one = create_user("claim-player-one")
    @player_two = create_user("claim-player-two")
    @game = create_game(@host, "Claim Game")
    @item = create_item("B", 1, "Shared item")
  end

  test "approving one request marks and resolves the same item throughout its game" do
    first_cell = create_cell(create_card(@game, @player_one), @item, "B1")
    second_cell = create_cell(create_card(@game, @player_two), @item, "B1")
    first_action = create_mark_request(@player_one, first_cell)
    second_action = create_mark_request(@player_two, second_cell)

    first_action.approve!

    assert first_cell.reload.is_marked?
    assert second_cell.reload.is_marked?
    assert_equal "approved", first_action.reload.status
    assert_equal "approved", second_action.reload.status
    assert @game.mark_memories.exists?(bingo_item: @item)
  end

  test "claiming an item does not mark the same item in another game" do
    other_host = create_user("other-host")
    other_player = create_user("other-player")
    other_game = create_game(other_host, "Other Game")
    own_cell = create_cell(create_card(@game, @player_one), @item, "B1")
    other_cell = create_cell(create_card(other_game, other_player), @item, "B1")

    create_mark_request(@player_one, own_cell).approve!

    assert own_cell.reload.is_marked?
    assert_not other_cell.reload.is_marked?
    assert_not other_game.mark_memories.exists?(bingo_item: @item)
  end

  test "late-created card applies remembered items and preserves free space" do
    items = create_full_item_pool
    remembered_item = items.fetch("B").first
    @game.claim_item!(remembered_item, approved_by: @admin)

    late_player = create_user("late-player")
    card = @game.bingo_cards.create!(user: late_player)

    assert card.bingo_cells.find_by!(bingo_item: remembered_item).is_marked?
    assert card.bingo_cells.find_by!(coordinate: "FREE").is_marked?
  end

  test "claiming an item does not overwrite a coordinate memory for another item" do
    other_item = create_item("B", 2, "Other item")
    conflicting_memory = @game.mark_memories.create!(
      bingo_item: other_item,
      coordinate: "B1",
      approved_by: @admin
    )

    claimed_memory = @game.claim_item!(@item, approved_by: @admin, coordinate: "B1")

    assert_equal other_item.id, conflicting_memory.reload.bingo_item_id
    assert_equal @item.id, claimed_memory.bingo_item_id
    assert_not_equal conflicting_memory.id, claimed_memory.id
    assert_equal "B1:item-#{@item.id}", claimed_memory.coordinate
  end

  test "repeated item claims reuse one memory" do
    first_memory = @game.claim_item!(@item, approved_by: @admin, coordinate: "B1")
    second_memory = @game.claim_item!(@item, approved_by: @admin, coordinate: "B1")

    assert_equal first_memory.id, second_memory.id
    assert_equal 1, @game.mark_memories.where(bingo_item: @item).count
  end

  test "mark memories can belong to bingo items while preserving coordinate-only memories" do
    item_memory = @game.mark_memories.create!(
      bingo_item: @item,
      coordinate: "B1",
      approved_by: @admin
    )
    coordinate_memory = @game.mark_memories.create!(coordinate: "I2")

    assert_equal @item, item_memory.reload.bingo_item
    assert_includes @item.bingo_game_mark_memories, item_memory
    assert_nil coordinate_memory.reload.bingo_item
  end

  private

  def create_user(uid, type = :regular)
    User.create!(uid: uid, username: uid, user_type: type)
  end

  def create_game(host, title)
    BingoGame.create!(host: host, title: title, status: "active", size: 5)
  end

  def create_item(column, row, content)
    BingoItem.create!(column_letter: column, row_number: row, content: content)
  end

  def create_card(game, user)
    BingoCard.insert_all!([{ bingo_game_id: game.id, user_id: user.id, created_at: Time.current, updated_at: Time.current }])
    game.bingo_cards.find_by!(user: user)
  end

  def create_cell(card, item, coordinate, marked: false)
    BingoCell.create!(bingo_card: card, bingo_item: item, coordinate: coordinate, is_marked: marked)
  end

  def create_mark_request(user, cell)
    PendingAction.create!(
      user: user,
      target: cell,
      action_type: "mark_cell",
      metadata: { coordinate: cell.coordinate }
    )
  end

  def create_full_item_pool
    columns = %w[B I N G O]
    items = columns.index_with do |column|
      next [@item] + 4.times.map { |index| create_item("B", index + 2, "B item #{index + 1}") } if column == "B"

      5.times.map { |index| create_item(column, (columns.index(column) * 15) + index + 1, "#{column} item #{index}") }
    end
    create_item("N", 99, "HOBBIT NOT PAYING ATTENTION")
    items
  end
end
