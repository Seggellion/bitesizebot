class Medium < ApplicationRecord
    belongs_to :user
    belongs_to :shard, optional: true

    has_one_attached :file # ActiveStorage association


    scope :staff_picks, -> { where(staff: true) }
    scope :approved, -> { where(approved: true) }



    validates :file, presence: true

    CATEGORIES = %w[screenshot content_page other].freeze

    validates :category, inclusion: { in: CATEGORIES }
  

    scope :screenshots, -> { where(category: 'screenshot') }

  end
  