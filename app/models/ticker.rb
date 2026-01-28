class Ticker < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  has_many :price_histories, dependent: :destroy
      has_rich_text :description

before_validation :generate_symbol, on: :create

  # Helper to get price or seed a default if a new stock is created

def chart_data
  price_histories
    .where("created_at >= ?", 48.hours.ago)
    .order(:created_at)
    .map { |h| [h.created_at, h.price.to_f] }
end

def candlestick_data
  price_histories.order(:created_at).map do |h|
    [
      h.created_at,
      h.open,
      h.high,
      h.low,
      h.close
    ]
  end
end

def volume_data
  price_histories.order(:created_at).map do |h|
    [h.created_at, h.volume]
  end
end



  def self.price_for(name)
    find_or_create_by(name: name.downcase) do |t|
      t.current_price = 100.0 # Starting IPO price
    end.current_price
  end

  private

def generate_symbol
  return if symbol.present? || name.blank?
  
  base_symbol = name.gsub(/[^0-9a-z]/i, '').first(3).upcase
  suggested_symbol = base_symbol
  counter = 1

  while Ticker.exists?(symbol: suggested_symbol)
    suggested_symbol = "#{base_symbol}#{counter}"
    counter += 1
  end

  self.symbol = suggested_symbol
end

end