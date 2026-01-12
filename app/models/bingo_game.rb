# app/models/bingo_game.rb
class BingoGame < ApplicationRecord
  # Relationships
  belongs_to :host, class_name: 'User', foreign_key: 'host_id'
  has_many :bingo_items, dependent: :destroy
  has_many :bingo_cards, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :size, presence: true, numericality: { only_integer: true, greater_than: 2 }

  # Scopes for the Admin Dashboard
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }

  def total_slots
    size * size
  end
end