# frozen_string_literal: true

puts "Seeding Bingo Items..."

BINGO_COLUMNS = {
  "B" => [
    "First chat message",
    "Streamer says hello",
    "Someone asks what game this is",
    "Sound alert triggers",
    "Mic check comment",
    "Chat says hi back",
    "Streamer adjusts volume",
    "Early lurker appears",
    "Viewer says \"first\"",
    "Stream starts late comment",
    "Someone asks about controls",
    "Streamer thanks a follower",
    "Chat emote spam",
    "Background music mentioned",
    "Streamer laughs"
  ],
  "I" => [
    "New follower alert",
    "Raid announced",
    "Streamer explains rules again",
    "Chat types !bingo",
    "Someone asks for giveaway",
    "Technical issue mentioned",
    "Streamer fixes something live",
    "Viewer says \"nice\"",
    "Chat repeats a joke",
    "Streamer misses something obvious",
    "Moderator speaks",
    "Viewer joins mid-sentence",
    "Chat says \"pog\"",
    "Streamer reads chat out loud",
    "Awkward silence"
  ],
  "N" => [
    "FREE SPACE",
    "Streamer says \"wait what\"",
    "Unexpected in-game event",
    "Chat reacts all at once",
    "Streamer forgets objective",
    "Someone clips the stream",
    "Streamer talks to themselves",
    "Chat corrects the streamer",
    "Streamer presses wrong button",
    "Viewer says \"lol\"",
    "Streamer re-explains strategy",
    "Chat goes quiet suddenly",
    "Streamer thanks a sub",
    "Streamer gets distracted",
    "Chat types same word"
  ],
  "G" => [
    "Gifted sub alert",
    "Streamer celebrates",
    "Chat spams emotes",
    "Someone asks about schedule",
    "Streamer mentions coffee",
    "Viewer says \"rip\"",
    "Streamer makes a bold claim",
    "Immediate regret",
    "Chat calls it",
    "Streamer blames lag",
    "Unexpected sound effect",
    "Streamer reacts late",
    "Chat says \"called it\"",
    "Streamer pauses to read chat",
    "Streamer explains lore"
  ],
  "O" => [
    "Big win moment",
    "Big fail moment",
    "Streamer facepalms",
    "Chat types \"F\"",
    "Streamer says \"one more\"",
    "Viewer asks for shoutout",
    "Streamer loses track of time",
    "Chat reminds streamer of goal",
    "Streamer says \"last try\"",
    "Streamer breaks character",
    "Chat explodes",
    "Streamer forgets chat is visible",
    "Streamer celebrates too early",
    "Chat roasts streamer",
    "Stream ends suddenly"
  ]
}

COLUMN_OFFSETS = {
  "B" => 0,   # 1..15
  "I" => 15,  # 16..30
  "N" => 30,  # 31..45
  "G" => 45,  # 46..60
  "O" => 60   # 61..75
}

ActiveRecord::Base.transaction do
  BingoItem.delete_all

  BINGO_COLUMNS.each do |column_letter, phrases|
    offset = COLUMN_OFFSETS.fetch(column_letter)

    phrases.each_with_index do |content, index|
      bingo_number = offset + index + 1

      BingoItem.create!(
        column_letter: column_letter,
        row_number: bingo_number,
        content: content
      )
    end
  end
end

puts "Seeded #{BingoItem.count} bingo items successfully."
