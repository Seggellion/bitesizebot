class Order < ApplicationRecord
  belongs_to :user
  has_many :attributed_items

  validates :shopify_order_id, presence: true
end
