class Ticker < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  has_many :price_histories, dependent: :destroy

  # Helper to get price or seed a default if a new stock is created

  def chart_data    
price_histories.order(:created_at).map { |h| [h.created_at, h.price.to_f] }
  end

  def self.price_for(name)
    find_or_create_by(name: name.downcase) do |t|
      t.current_price = 100.0 # Starting IPO price
    end.current_price
  end
end