class BingoItem < ApplicationRecord
  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_games, through: :bingo_game_items
  has_many :bingo_cells, dependent: :destroy

  validates :content, presence: true
end