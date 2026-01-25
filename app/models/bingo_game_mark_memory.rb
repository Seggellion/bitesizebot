class BingoGameMarkMemory < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :approved_by, class_name: "User", optional: true

  validates :coordinate, presence: true, uniqueness: { scope: :bingo_game_id }
end
