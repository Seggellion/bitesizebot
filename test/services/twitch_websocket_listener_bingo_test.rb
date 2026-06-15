require "test_helper"

class TwitchWebsocketListenerBingoTest < ActiveSupport::TestCase
  setup do
    Setting.set("current-theme", "Hobbit")
    @host = create_user("listener-host")
    @bot = create_user("listener-bot", type: :bot)
    create_full_bingo_item_pool
  end

  test "bot notification bingo join works when no mark memories exist" do
    game = create_game("Listener Join Game")
    messages = capture_twitch_messages do
      TwitchWebsocketListener.handle_notification(chat_event("listener-viewer", "ListenerViewer", "!bingo join"))
    end

    viewer = User.find_by!(uid: "listener-viewer")
    card = game.bingo_cards.find_by!(user: viewer)
    assert_equal 25, card.bingo_cells.count
    assert_match(/Welcome to Bitesize Bingo!/, messages.last)
  end

  test "bot notification bingo join works when item mark memories exist" do
    game = create_game("Listener Remembered Game")
    remembered_item = BingoItem.find_by!(column_letter: "B", row_number: 1)
    game.claim_item!(remembered_item, approved_by: @host, coordinate: "B1")

    capture_twitch_messages do
      TwitchWebsocketListener.handle_notification(chat_event("listener-memory-viewer", "MemoryViewer", "!bingo join"))
    end

    viewer = User.find_by!(uid: "listener-memory-viewer")
    card = game.bingo_cards.find_by!(user: viewer)
    assert card.bingo_cells.find_by!(bingo_item: remembered_item).is_marked?
  end

  private

  def capture_twitch_messages
    messages = []
    sender = ->(_broadcaster_id, _sender_id, message) { messages << message }

    SystemSetting.stub(:bot_enabled?, true) do
      TwitchWebsocketListener.stub(:is_follower?, true) do
        ActivityEngine.stub(:process_chat, nil) do
          TwitchService.stub(:send_chat_message, sender) do
            yield
          end
        end
      end
    end

    messages
  end

  def chat_event(uid, display_name, text)
    {
      "badges" => [],
      "broadcaster_user_id" => @host.uid,
      "chatter_user_id" => uid,
      "chatter_user_login" => display_name.downcase,
      "chatter_user_name" => display_name,
      "message" => { "text" => text }
    }
  end

  def create_user(uid, type: :regular)
    User.create!(uid: uid, username: uid, user_type: type)
  end

  def create_game(title)
    BingoGame.create!(host: @host, title: title, status: "invite", size: 5)
  end

  def create_full_bingo_item_pool
    BingoItem.create!(column_letter: "N", row_number: nil, content: "HOBBIT NOT PAYING ATTENTION")

    %w[B I N G O].each do |column|
      (1..5).each do |row|
        BingoItem.create!(column_letter: column, row_number: row, content: "#{column}#{row} listener item")
      end
    end
  end
end
