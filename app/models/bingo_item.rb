# app/models/bingo_item.rb
class BingoItem < ApplicationRecord
  belongs_to :bingo_game
  has_many :bingo_cells, dependent: :destroy

  validates :content, presence: true
end