class BingoGameItem < ApplicationRecord
  belongs_to :bingo_game
  belongs_to :bingo_item
end