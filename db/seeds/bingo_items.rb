# frozen_string_literal: true

puts "Seeding Bingo Items..."

BINGO_COLUMNS = {
  "B" => ["Forgets What She's Doing", "Gets in then out of Pilot Seat", "Walks Away from Stream", "Passenger Princess", "Cargo Box to Anyones Face", "Kills/Causes Teammate Death", "Activity Other Than Cargo", "!Phrasing", "Hasn't Seen A Movie", "Blows Up Balloon", "Gets An Adult Beverage", "Eats On Stream", "Complains She's Hungry", "Confused Writing On Balloon", "Flirts With Seggellion"],
  "I" => ["Flying Upside Down", "3rd Person Quantum View", "Floating In Space (not in ship)", "Landing Gear Still Up", "Landing Gear Still Down", "Fights Cargo Box Into Ship", "Yells At/In/Near Elevators", "Pulls Gun On Accident", "Exits To Menu", "Gets Lost", "Using Stock Paint", "Takes Out Wrong Ship", "Forgets How To Do Something", "Doesn't Set Spawn Location", "Hangar Eats Ship/Doesn't Spawn"],
  "N" => ["Says the word 'POTATO'", "Yells at Any Teammate", "Curses For Any Reason", "Quotes Any Line From Spaceballs", "Starts Singing", "Stream Issues", "JoshyWashyPlayz Has To Delete VOD/Clip", "Someone Gifts A Sub", "Pops A Balloon", "Gets Tipsy", "Blows Up A Balloon", "Blows Up A Balloon Animal", "Gets Finger Stuck Tying Balloon", "Golf Claps"],
  "G" => ["Discord Chat Talking Over Hobbit", "Damage from Running Into Player", "ToddFoxx_ Enters Chat to Cuss", "Any Gigantified Sausage Emote", "Daft Falls Out Of Ship", "Arcane Over Complicates Things", "Nut Bucket Redeem", "Incoming Raid", "New Follower (actual)", "Balloon Redeem For Daft", "Seggellion Mentions Boats", "Co-Op Stream Together/Shared Chat", "HMS_Thunderwolf Too Tired For this", "IRL Friend/Sibling In Chat", "Teammate Repeatedly Asks for Invite"],
  "O" => ["Crash Landing", "Hydration Under 20%", "Gets Knocked Out", "Gets In A Tank", "No Helmet On", "PTV Racing", "Goes FPS Anywhere", "Has A Bad Idea", "Hobbit Death", "Puts a Ship in a Ship", " Goes Through Nyx Jump Gate", "Goes Through Pyro Jump Gate", "Landing On A Dark Planet/Moon", "Backspaces On Purpose", "Does a Bunker Mission"]
}

COLUMN_OFFSETS = { "B" => 0, "I" => 15, "N" => 30, "G" => 45, "O" => 60 }

ActiveRecord::Base.transaction do
  puts "Cleaning old items..."
  BingoItem.delete_all

  # 1. CREATE THE FREE SPACE ITEM INSIDE THE TRANSACTION
  BingoItem.create!(
    column_letter: "N",
    row_number: 99, 
    content: "HOBBIT NOT PAYING ATTENTION"
  )

  # 2. SEED THE REST
  BINGO_COLUMNS.each do |column_letter, phrases|
    offset = COLUMN_OFFSETS.fetch(column_letter)

    phrases.each_with_index do |content, index|
      # Skip if this phrase happens to be the free space text to avoid duplicates
      next if content == "HOBBIT NOT PAYING ATTENTION"

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
