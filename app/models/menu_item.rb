class MenuItem < ApplicationRecord
  belongs_to :menu
  belongs_to :parent, class_name: 'MenuItem', optional: true
  has_many :children, class_name: 'MenuItem', foreign_key: 'parent_id', dependent: :destroy
  
  enum :item_type, { custom: 0, page: 1, category: 2, service: 3 }

  # COMBINE THESE INTO ONE LINE
  # Default column is 'position', so you don't strictly need to specify it if it's 'position'
  # but for clarity:
  acts_as_list scope: :menu_id, column: :position

  validates :url, presence: true
  
  scope :roots, -> { where(parent_id: nil) }

  before_create :set_default_position

  private

  def set_default_position
    # Optimization: Use strict scoping to avoid nil errors
    max = MenuItem.where(menu_id: self.menu_id, parent_id: self.parent_id).maximum(:position) || 0
    self.position ||= max + 1
  end
end