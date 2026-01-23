class User < ApplicationRecord
    has_many :pages, dependent: :destroy
    has_many :posts, dependent: :destroy
    has_many :media, dependent: :destroy
    has_many :comments, dependent: :destroy
    has_many :contact_messages, foreign_key: :email, primary_key: :email
    has_many :posts, dependent: :destroy
    has_many :bingo_cards, dependent: :destroy
has_many :investments, dependent: :destroy
    has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  store :global_inventory, coder: JSON
  store :purchased_items, coder: JSON
has_many :won_games, class_name: 'BingoGame', foreign_key: 'winner_id'
has_many :ledger_entries, dependent: :destroy
has_many :giveaway_entries, dependent: :destroy

  # Define roles
enum :user_type, { admin: 0, regular: 1, bot: 5 }
  attr_accessor :twitch_scopes


  def can_afford?(cost)
    wallet >= cost
  end

    # Example method to add a purchased item
    def add_purchased_item(item_name)
      self.purchased_items ||= []
      self.purchased_items << { name: item_name, purchased_at: Time.current }
      save
    end

has_many :won_giveaways, class_name: 'Giveaway', foreign_key: 'winner_id', dependent: :nullify

    validates :uid, presence: true, uniqueness: true

 def self.bot_user
    find_by(user_type: :bot)
  end

# Helper to check for the specific ban tag
  def banned_from_giveaways?    
    tags.where(name: 'giveaway_banned').exists?
  end

  # Scope to help with the "Secret" filter in queries
  scope :not_banned_from_giveaways, -> {
    where.not(id: Tagging.where(taggable_type: 'User', tag: Tag.where(name: 'giveaway_banned')).select(:taggable_id))
  }

  def self.recent_winners(time_frame)
  joins(:won_giveaways).where("giveaways.drawn_at >= ?", time_frame.ago)
end

# app/models/user.rb
def following_broadcaster?
  broadcaster_id = SystemSetting.broadcaster_uid
  TwitchWebsocketListener.is_follower?(broadcaster_id, self.uid)
end

def won_recently?(time_frame)
  won_giveaways.where("drawn_at >= ?", time_frame.ago).exists?
end


  def self.admin_exists?
    where(user_type: :admin).exists?
  end

 def admin?
    user_type == 'admin'
  end

    def bot?
    user_type == 'bot'
  end


  def self.broadcaster
    User.find_by_uid(SystemSetting.broadcaster_uid)
  end
  

  end
  