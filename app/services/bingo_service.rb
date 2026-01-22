# app/services/bingo_service.rb
class BingoService
  REPLACEMENT_COST = 2000
  MAX_REPLACEMENTS = 2

  def self.process_command(uid, username, broadcaster_uid, text)
    host = User.find_by(uid: broadcaster_uid)
    return "Host not found." unless host

    command = text.downcase.strip
    
    # 1. Global Host Commands
    case command
    when "!bingo start"
      return start_game(host)
    when "!bingo end"
      return end_game(host)
    when "!bingo halt"
      return halt_game(host)
    end

    # 2. Find the current game
    game = BingoGame.where(host: host, status: ['invite', 'active']).last
    return "No active game right now! Type !bingo start to begin." unless game

    # 3. Identify the Viewer
    viewer = User.find_or_create_by(uid: uid) do |u|
      u.provider = 'twitch'
      u.username = username
      u.user_type = 1
    end

    # 4. Command Dispatcher
    case command
    when "!bingo join"
      # Only block joining if the game is already active
      if game.status == 'active'
        return "The game has already started! Too late to join."
      end
      return join_game(viewer, game)

    when "!bingo card"
      return list_card_cells(viewer, game)

    when "!bingo replace"
      return request_replacement(viewer, game)

    when "!bingo win"
      return request_win(viewer, game)

    when /^!bingo mark\s+([a-z])(\d+)/i
      return handle_mark(viewer, game, $1, $2)

    when /^!bingo explain\s+([a-z])(\d+)/i
      return explain_cell(viewer, game, $1, $2)

    else
      return "Command not recognized. Try !bingo join, !bingo card, or !bingo mark."
    end
  end

  # --- Helper Methods ---

  def self.join_game(viewer, game)
    return "You're already in!" if game.bingo_cards.exists?(user: viewer)
    game.bingo_cards.create!(user: viewer)
    "Welcome to Bitesize Bingo! Your card is ready."
  end

  def self.handle_mark(viewer, game, col, row)
    request_mark(viewer, game, col.upcase, row.to_i)
  end

  def self.request_replacement(viewer, game)
    card = game.bingo_cards.find_by(user: viewer)
    return "You need to join the game first!" unless card
    return "The game is active! No more replacements." if game.status == 'active'
    return "You've reached the replacement limit." if card.replacement_count >= MAX_REPLACEMENTS

    if card.replace_card!(REPLACEMENT_COST)
      "Card replaced! #{REPLACEMENT_COST} currency deducted."
    else
      card.errors.full_messages.to_sentence
    end
  end

  def self.request_mark(viewer, game, col_letter, row_num)
    card = game.bingo_cards.find_by(user: viewer)
    return "You aren't in this game! Type !bingo join first." unless card

    coord = "#{col_letter.upcase}#{row_num}"
    cell = card.bingo_cells.find_by(coordinate: coord)
    
    return "Invalid cell coordinate!" unless cell
    return "That's the free space!" if cell.coordinate == "FREE" || cell.bingo_item&.content == "FREE"
    return "That cell is already marked!" if cell.is_marked
    
    if PendingAction.exists?(target: cell, status: 'pending')
      return "A request for #{coord} is already awaiting approval!"
    end

    PendingAction.create!(
      user: viewer,
      target: cell,
      action_type: 'mark_cell',
      metadata: { coordinate: coord }
    )

    "Request sent! An admin will review your mark for #{coord}."
  end

  def self.explain_cell(viewer, game, col_letter, row_num)
    card = game.bingo_cards.find_by(user: viewer)
    return "You need to !bingo join first to see your card!" unless card

    coord = "#{col_letter.upcase}#{row_num.to_i}"
    cell = card.bingo_cells.includes(:bingo_item).find_by(coordinate: coord)
    return "Cell #{coord} not found on your card." unless cell

    item_content = cell.bingo_item.content
    "Cell #{coord}: #{item_content}"
  end

  def self.request_win(viewer, game)
    card = game.bingo_cards.find_by(user: viewer)
    return "You aren't in this game!" unless card
    
    unless card.verify_win
      viewer.decrement!(:karma, 50)
      return "False Bingo! You don't have 5 in a row."
    end

    if PendingAction.exists?(user: viewer, action_type: 'claim_win', status: 'pending')
      return "Your win claim is already being reviewed by an admin!"
    end

    PendingAction.create!(
      user: viewer,
      target: card,
      action_type: 'claim_win'
    )

    "Win claim submitted! An admin will verify your card shortly. Good luck!"
  end

  def self.list_card_cells(viewer, game)
    card = game.bingo_cards.find_by(user: viewer)
    return "You need to !bingo join first to see your card!" unless card

    cells = card.bingo_cells.includes(:bingo_item)
    column_order = ["B", "I", "N", "G", "O"]
    grouped = cells.group_by { |cell| cell.bingo_item&.column_letter }

    formatted_card = column_order.map do |letter|
      column_cells = grouped[letter] || []
      
      if letter == "N"
        free_cell = column_cells.detect { |c| c.coordinate == "FREE"}
        numbers = column_cells.reject { |c| c == free_cell }.sort_by { |c| c.bingo_item.row_number || 0 }
        final_list = [numbers[0]&.coordinate, numbers[1]&.coordinate, free_cell&.coordinate, numbers[2]&.coordinate, numbers[3]&.coordinate].compact
      else
        final_list = column_cells.sort_by { |c| c.bingo_item.row_number || 0 }.map(&:coordinate)
      end
      final_list.join(', ')
    end.join(' - - - ')

    "Your Card (TOP TO BOTTOM) [#{viewer.username}]: #{formatted_card}"
  end

  def self.start_game(host)
    BingoGame.where(host: host, status: ['invite', 'active']).update_all(status: 'ended', ended_at: Time.current)
    new_game = BingoGame.create!(
      host: host,
      title: "#{host.username}'s Game - #{Time.current.strftime('%m/%d')}",
      status: 'invite',
      size: 5,
      started_at: Time.current
    )
    "A new Bingo game has started! Type !bingo join to play."
  end

  def self.halt_game(host)
    game = BingoGame.find_by(host: host, status: 'invite')
    return "There is no game in 'invite' mode to halt." unless game
    game.update!(status: 'active')
    "Invites closed! The game is now ACTIVE. Good luck everyone!"
  end

  def self.end_game(host)
    game = BingoGame.where(host: host, status: ['invite', 'active']).last
    return "There is no active game to end." unless game
    game.update!(status: 'ended', ended_at: Time.current)
    "The Bingo game has been ended. Thanks for playing!"
  end
end