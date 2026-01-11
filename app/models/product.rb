class Product < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :category, optional: true
    has_rich_text :content
  has_many :product_tags, dependent: :destroy
  has_many :tags, through: :product_tags

  has_many :attributed_items

  validates :title, :price, presence: true

    has_many_attached :images
    extend FriendlyId
    friendly_id :title, use: :slugged
  has_many :product_listings, dependent: :destroy

validates :slug, uniqueness: true
  validates :item_id, uniqueness: true

  validates :requirements, presence: true

 store_accessor :requirements

  def template_file
      template.present? ? template : 'show'
    end

  def requirement_met?(city_commodities)
    requirements.all? do |name, amount|
      commodity = city_commodities.find { |c| c.item_name == name }
      commodity && commodity.quantity >= amount.to_i
    end
  end

end
