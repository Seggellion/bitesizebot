class BingoGame < ApplicationRecord
  belongs_to :host, class_name: 'User'
  
  has_many :bingo_game_items, dependent: :destroy
  has_many :bingo_items, through: :bingo_game_items
  
  has_many :bingo_cards, dependent: :destroy
  
  validates :title, presence: true
end