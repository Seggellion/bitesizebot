# app/services/bingo_service.rb
class BingoService
  def self.process_command(uid, username, broadcaster_uid, text)
    host = User.find_by(uid: broadcaster_uid)
    return "Host not found." unless host

    # Handle commands that don't necessarily require an active game first
    case text.downcase
    when "!bingo start"
      return start_game(host)
    when "!bingo end"
      return end_game(host)
    end

    game = BingoGame.find_by(host: host, status: 'active')
    
    return "No active game right now!" unless game

    viewer = User.find_or_create_by(uid: uid) do |u|
        u.provider = 'twitch'
        u.username = username
        end

    case text.downcase
    when "!bingo join"        
      return "You're already in!" if game.bingo_cards.exists?(user: viewer)
      game.bingo_cards.create!(user: viewer)
      return nil # Listener handles the join message

    when /^!bingo explain\s+([a-z])(\d+)/i
      col_letter = $1.upcase
      row_num = $2.to_i
      return explain_cell(viewer, game, col_letter, row_num)

    when /^!bingo mark\s+([a-z])(\d+)/i
      col_letter = $1.upcase      
      row_num = $2.to_i
      return request_mark(viewer, game, col_letter, row_num)
    end
  end

def self.explain_cell(viewer, game, col_letter, row_num)
    
    card = game.bingo_cards.find_by(user: viewer)
    return "You need to !bingo join first to see your card!" unless card

    coord = "#{col_letter}#{row_num}"
    cell = card.bingo_cells.includes(:bingo_item).find_by(coordinate: coord)

    return "Cell #{coord} not found on your card." unless cell

    # Accessing the content through the relationship
    item_content = cell.bingo_item.content
    "Cell #{coord}: #{item_content}"
  end


def self.start_game(host)
    # 1. Close any existing active games for this host
    BingoGame.where(host: host, status: 'active').update_all(status: 'ended', ended_at: Time.current)

    # 2. Create new game
    # Note: You may want a more robust way to select/randomize bingo_items here
    new_game = BingoGame.create!(
      host: host,
      title: "#{host.username}'s Game - #{Time.current.strftime('%m/%d')}",
      status: 'active',
      size: 5,
      started_at: Time.current
    )

    # Optional: Automatically associate items if you have a pool of BingoItems
    # items = BingoItem.limit(25).pluck(:id)
    # items.each { |item_id| BingoGameItem.create!(bingo_game: new_game, bingo_item_id: item_id) }

    "A new Bingo game has started! Type !bingo join to play."
  end

  def self.end_game(host)
    game = BingoGame.where(host: host, status: 'active').last
    return "There is no active game to end." unless game

    game.update!(status: 'ended', ended_at: Time.current)
    "The Bingo game has been ended. Thanks for playing!"
  end

  

  def self.request_mark(viewer, game, col_letter, row_num)
    
card = game.bingo_cards.find_by(user: viewer)
  coord = "#{col_letter.upcase}#{row_num}"
  
  # Find the cell directly by the human-readable coordinate
  cell = card.bingo_cells.find_by(coordinate: coord)
    
    
    
    return "Invalid cell coordinate!" unless cell
    return "That cell is already marked!" if cell.is_marked
    # Check if a request is already pending for this specific cell
    if PendingAction.exists?(target: cell, status: 'pending')
      return "A request for #{col_letter}#{row_num} is already awaiting approval!"
    end

    PendingAction.create!(
      user: viewer,
      target: cell,
      action_type: 'mark_cell',
      metadata: { coordinate: "#{col_letter}#{row_num}" }
    )

    "Request sent! An admin will review your mark for #{col_letter}#{row_num}."
  end
end