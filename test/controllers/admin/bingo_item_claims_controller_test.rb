require "test_helper"

class Admin::BingoItemClaimsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.set("current-theme", "Hobbit")
    @admin = create_user("controller-admin", :admin)
    @host = create_user("controller-host")
    @player_one = create_user("controller-player-one")
    @player_two = create_user("controller-player-two")
    @game = create_game(@host, "Controller Game")
    @item = BingoItem.create!(column_letter: "B", row_number: 1, content: "Controller item")
    sign_in(@admin)
  end

  test "manual marking cascades and unmarking stays local without deleting memory" do
    first_cell = create_cell(create_card(@game, @player_one))
    second_cell = create_cell(create_card(@game, @player_two))

    patch toggle_admin_bingo_cell_path(first_cell)

    assert first_cell.reload.is_marked?
    assert second_cell.reload.is_marked?
    assert @game.mark_memories.exists?(bingo_item: @item)

    patch toggle_admin_bingo_cell_path(first_cell)

    assert_not first_cell.reload.is_marked?
    assert second_cell.reload.is_marked?
    assert @game.mark_memories.exists?(bingo_item: @item)
  end

  test "bulk approval uses item claims" do
    first_cell = create_cell(create_card(@game, @player_one))
    second_cell = create_cell(create_card(@game, @player_two))
    first_action = create_request(@player_one, first_cell)
    second_action = create_request(@player_two, second_cell)

    patch bulk_approve_admin_pending_actions_path

    assert first_cell.reload.is_marked?
    assert second_cell.reload.is_marked?
    assert_equal "approved", first_action.reload.status
    assert_equal "approved", second_action.reload.status
    assert @game.mark_memories.exists?(bingo_item: @item)
  end

  test "approve similar cannot affect another game" do
    other_host = create_user("controller-other-host")
    other_player = create_user("controller-other-player")
    other_game = create_game(other_host, "Controller Other Game")
    own_cell = create_cell(create_card(@game, @player_one))
    other_cell = create_cell(create_card(other_game, other_player))
    own_action = create_request(@player_one, own_cell)
    other_action = create_request(other_player, other_cell)

    patch approve_similar_admin_pending_action_path(own_action)

    assert own_cell.reload.is_marked?
    assert_equal "approved", own_action.reload.status
    assert_not other_cell.reload.is_marked?
    assert_equal "pending", other_action.reload.status
    assert_not other_game.mark_memories.exists?(bingo_item: @item)
  end

  private

  def sign_in(user)
    get "/auth/test/callback", env: {
      "omniauth.auth" => {
        "provider" => "test",
        "uid" => user.uid,
        "info" => { "name" => user.username },
        "credentials" => {}
      }
    }
  end

  def create_user(uid, type = :regular)
    User.create!(uid: uid, username: uid, user_type: type)
  end

  def create_game(host, title)
    BingoGame.create!(host: host, title: title, status: "active", size: 5)
  end

  def create_card(game, user)
    BingoCard.insert_all!([{ bingo_game_id: game.id, user_id: user.id, created_at: Time.current, updated_at: Time.current }])
    game.bingo_cards.find_by!(user: user)
  end

  def create_cell(card)
    BingoCell.create!(bingo_card: card, bingo_item: @item, coordinate: "B1", is_marked: false)
  end

  def create_request(user, cell)
    PendingAction.create!(user: user, target: cell, action_type: "mark_cell", metadata: { coordinate: "B1" })
  end
end
