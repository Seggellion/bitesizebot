class Download < ApplicationRecord
  belongs_to :shard
  belongs_to :category, optional: true

  validates :title, presence: true
  validates :link_url, presence: true
  validates :link_text, presence: true

  default_scope { order(:order, created_at: :asc) }
end
