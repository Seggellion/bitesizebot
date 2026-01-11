class MenuItem < ApplicationRecord
  belongs_to :menu
  belongs_to :parent, class_name: 'MenuItem', optional: true
  has_many :children, class_name: 'MenuItem', foreign_key: 'parent_id', dependent: :destroy
  enum :item_type, { custom: 0, page: 1, category: 2, service: 3 }
  acts_as_list order: 'position'

  validates :url, presence: true
  acts_as_list scope: :menu_id

  scope :roots, -> { where(parent_id: nil) }

    before_create :set_default_position

  private

  def set_default_position
    max = MenuItem.where(menu_id: self.menu_id, parent_id: self.parent_id).maximum(:position) || 0
    self.position ||= max + 1
  end

end
