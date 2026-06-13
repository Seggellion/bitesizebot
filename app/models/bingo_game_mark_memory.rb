class BingoGameMarkMemory < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :bingo_item, optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  validates :coordinate, presence: true, uniqueness: { scope: :bingo_game_id }
  validates :bingo_item_id,
            uniqueness: { scope: :bingo_game_id },
            allow_nil: true
end
