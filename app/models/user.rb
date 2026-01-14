class User < ApplicationRecord
    has_many :pages, dependent: :destroy
    has_many :posts, dependent: :destroy
    has_many :media, dependent: :destroy
    has_many :comments, dependent: :destroy
    has_many :contact_messages, foreign_key: :email, primary_key: :email
    has_many :posts, dependent: :destroy
    has_many :shard_users, dependent: :destroy
  has_many :blessed_items, dependent: :destroy
    has_many :bingo_cards, dependent: :destroy

  store :global_inventory, coder: JSON
  store :purchased_items, coder: JSON
has_many :won_games, class_name: 'BingoGame', foreign_key: 'winner_id'


    # Example method to add a purchased item
    def add_purchased_item(item_name)
      self.purchased_items ||= []
      self.purchased_items << { name: item_name, purchased_at: Time.current }
      save
    end

    validates :uid, presence: true, uniqueness: true

  # Define roles
  enum :user_type, { admin: 0, regular: 1 }

  

  def self.admin_exists?
    where(user_type: :admin).exists?
  end

  def admin?
    user_type == 'admin'
  end

  end
  