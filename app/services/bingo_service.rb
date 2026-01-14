# app/services/bingo_service.rb
class BingoService
  def self.process_command(uid, username, broadcaster_uid, text)
    host = User.find_by(uid: broadcaster_uid)
    return "Host not found." unless host

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