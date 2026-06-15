require "test_helper"

class BingoServiceModeratorApprovalTest < ActiveSupport::TestCase
  setup do
    Setting.set("current-theme", "Hobbit")
    @host = create_user("approval-host")
    @player = create_user("approval-player")
    @other_player = create_user("approval-other-player")
    @mod_one = create_user("approval-mod-one")
    @mod_two = create_user("approval-mod-two")
    @viewer = create_user("approval-viewer")
    @game = create_game(@host, "Approval Game")
    @item = create_item("B", 3, "Find the hidden key")
    @cell = create_cell(create_card(@game, @player), @item, "B3")
  end

  test "mark request message includes requester coordinate item and instructions" do
    message = BingoService.request_mark(@player, @game, "B", 3)

    assert_includes message, @player.username
    assert_includes message, "B3"
    assert_includes message, @item.content
    assert_includes message, "!bingo approve B3"
    assert_includes message, "2 approvals required"
  end

  test "two distinct moderators approve through the item claim cascade" do
    other_cell = create_cell(create_card(@game, @other_player), @item, "B3")
    first_action = create_request(@player, @cell)
    second_action = create_request(@other_player, other_cell)

    first_response = approve(@mod_one)
    second_response = approve(@mod_two)

    assert_includes first_response, "1/2 approvals"
    assert_includes second_response, "approved after 2/2"
    assert @cell.reload.is_marked?
    assert other_cell.reload.is_marked?
    assert_equal "approved", first_action.reload.status
    assert_equal "approved", second_action.reload.status
    assert @game.mark_memories.exists?(bingo_item: @item, approved_by: @mod_two)
  end

  test "the same moderator cannot approve twice" do
    action = create_request(@player, @cell)

    assert_includes approve(@mod_one), "1/2 approvals"
    assert_includes approve(@mod_one), "already has an approval"
    assert_equal 1, action.pending_action_votes.count
    assert_equal "pending", action.reload.status
  end

  test "normal viewers cannot approve" do
    action = create_request(@player, @cell)

    response = BingoService.approve_mark(@viewer, @game, "B", 3, is_mod: false)

    assert_equal "Only Twitch moderators can approve bingo marks.", response
    assert_equal 0, action.pending_action_votes.count
    assert_equal "pending", action.reload.status
  end

  test "a moderator requester may vote but still needs a second moderator" do
    action = create_request(@mod_one, @cell)

    assert_includes approve(@mod_one), "1/2 approvals"
    assert_equal "pending", action.reload.status
    assert_includes approve(@mod_two), "approved after 2/2"
    assert_equal "approved", action.reload.status
  end

  test "approval does not cross bingo games" do
    other_host = create_user("approval-other-host")
    other_game = create_game(other_host, "Other Approval Game")
    other_item = create_item("B", 33, "Other game item")
    other_cell = create_cell(create_card(other_game, @other_player), other_item, "B3")
    other_action = create_request(@other_player, other_cell)
    own_action = create_request(@player, @cell)

    approve(@mod_one)
    approve(@mod_two)

    assert_equal "approved", own_action.reload.status
    assert_equal "pending", other_action.reload.status
    assert_not other_cell.reload.is_marked?
  end

  test "different items at the same coordinate are rejected as ambiguous" do
    other_item = create_item("B", 4, "Different B3 item")
    other_cell = create_cell(create_card(@game, @other_player), other_item, "B3")
    first_action = create_request(@player, @cell)
    second_action = create_request(@other_player, other_cell)

    response = approve(@mod_one)

    assert_includes response, "ambiguous"
    assert_equal "pending", first_action.reload.status
    assert_equal "pending", second_action.reload.status
    assert_equal 0, PendingActionVote.count
  end

  test "bingo join command creates a card and generated cells" do
    create_full_bingo_item_pool
    @game.update!(status: "ended")
    invite_game = create_game(@host, "Joinable Game", status: "invite")
    viewer_uid = "join-command-viewer"

    response = BingoService.process_command(viewer_uid, "JoinViewer", @host.uid, "!bingo join")

    viewer = User.find_by!(uid: viewer_uid)
    card = invite_game.bingo_cards.find_by!(user: viewer)
    assert_equal "Welcome to Bitesize Bingo! Your card is ready.", response
    assert_equal 25, card.bingo_cells.count
  end

  test "bingo join command applies existing item mark memories to generated cells" do
    create_full_bingo_item_pool
    @game.update!(status: "ended")
    invite_game = create_game(@host, "Remembered Joinable Game", status: "invite")
    remembered_item = BingoItem.find_by!(column_letter: "B", row_number: 1)
    invite_game.claim_item!(remembered_item, approved_by: @mod_two, coordinate: "B1")

    response = BingoService.process_command("remembered-join-viewer", "RememberedJoin", @host.uid, "!bingo join")

    viewer = User.find_by!(uid: "remembered-join-viewer")
    card = invite_game.bingo_cards.find_by!(user: viewer)
    assert_equal "Welcome to Bitesize Bingo! Your card is ready.", response
    assert card.bingo_cells.find_by!(bingo_item: remembered_item).is_marked?
    assert_equal 1, invite_game.mark_memories.where(bingo_item: remembered_item).count
  end

  test "bingo approve command routes to moderator approval" do
    action = create_request(@player, @cell)

    response = BingoService.process_command(@mod_one.uid, @mod_one.username, @host.uid, "!bingo approve B3", is_mod: true)

    assert_includes response, "B3 approval received"
    assert_equal 1, action.pending_action_votes.count
    assert_equal "pending", action.reload.status
  end

  test "bingo mark command creates a pending request" do
    response = BingoService.process_command(@player.uid, @player.username, @host.uid, "!bingo mark B3")

    assert_includes response, "#{@player.username} requested B3"
    assert PendingAction.pending.exists?(user: @player, target: @cell, action_type: "mark_cell")
  end

  test "unknown bingo subcommands do not affect join mark or approve flows" do
    response = BingoService.process_command(@player.uid, @player.username, @host.uid, "!bingo mystery")

    assert_equal "Command not recognized. Try !bingo join, !bingo card, or !bingo mark.", response
    assert_equal 0, PendingAction.count

    mark_response = BingoService.process_command(@player.uid, @player.username, @host.uid, "!bingo mark B3")
    approve_response = BingoService.process_command(@mod_one.uid, @mod_one.username, @host.uid, "!bingo approve B3", is_mod: true)

    assert_includes mark_response, "#{@player.username} requested B3"
    assert_includes approve_response, "B3 approval received"
  end

  test "twitch viewer lookup reuses existing uid without requiring provider match" do
    existing_viewer = User.create!(uid: "existing-twitch-uid", username: "ExistingViewer", user_type: :regular)

    viewer = TwitchWebsocketListener.find_or_create_twitch_viewer(existing_viewer.uid, "ExistingViewer")

    assert_equal existing_viewer, viewer
    assert_equal "twitch", viewer.provider
    assert_equal 1, User.where(uid: existing_viewer.uid).count
  end

  private

  def approve(moderator)
    BingoService.approve_mark(moderator, @game, "B", 3, is_mod: true)
  end

  def create_user(uid)
    User.create!(uid: uid, username: uid, user_type: :regular)
  end

  def create_game(host, title, status: "active")
    BingoGame.create!(host: host, title: title, status: status, size: 5)
  end

  def create_item(column, row, content)
    BingoItem.create!(column_letter: column, row_number: row, content: content)
  end

  def create_full_bingo_item_pool
    create_item("N", nil, "HOBBIT NOT PAYING ATTENTION")

    %w[B I N G O].each do |column|
      (1..5).each do |row|
        create_item(column, row, "#{column}#{row} generated item")
      end
    end
  end

  def create_card(game, user)
    BingoCard.insert_all!([{ bingo_game_id: game.id, user_id: user.id, created_at: Time.current, updated_at: Time.current }])
    game.bingo_cards.find_by!(user: user)
  end

  def create_cell(card, item, coordinate)
    BingoCell.create!(bingo_card: card, bingo_item: item, coordinate: coordinate, is_marked: false)
  end

  def create_request(user, cell)
    PendingAction.create!(
      user: user,
      target: cell,
      action_type: "mark_cell",
      metadata: { coordinate: cell.coordinate }
    )
  end
end
