# app/models/transaction_item.rb
class TransactionItem < ApplicationRecord
  belongs_to :parent_transaction, class_name: "Transaction", foreign_key: "transaction_id"
  has_one :user, through: :parent_transaction

  validates :item_name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def self.user_contributions(player_uuid, days = 90)
    start_date = days.days.ago
    select(
      'transactions.city_id AS city_id',
      'cities.name AS city_name',
      'city_commodities.category AS commodity_type',
      'SUM(transaction_items.weight) AS total_contribution'
    )
      .joins(:parent_transaction)
      .joins('INNER JOIN city_commodities ON city_commodities.item_name = transaction_items.item_name')
      .joins('INNER JOIN cities ON cities.id = transactions.city_id')
      .where('transactions.player_uuid = ?', player_uuid)
      .where('transaction_items.created_at >= ?', start_date)
      .group('transactions.city_id, cities.name, city_commodities.category')
      .order('transactions.city_id, total_contribution DESC')
  end

  # Backward-compatible:
  # - leaderboard(city_id, 30)
  # - leaderboard(city_id, shard_id: 3, days: 30)

def self.leaderboard(city_id = nil, days = 60, shard_id: nil)
  # 1. Handle the argument parsing
  if days.is_a?(Hash)
    opts     = days
    shard_id = opts[:shard_id]
    days     = opts[:days] || 30
  end

  start_date = days.to_i.days.ago

  # 2. Join SQL (unchanged logic, just ensures per-row matching)
  fuzzy_join_sql = <<~SQL.squish
    INNER JOIN city_commodities 
      ON city_commodities.city_id = transactions.city_id 
      AND city_commodities.shard_id = transactions.shard_id
      AND (
        transaction_items.item_name ILIKE city_commodities.item_name 
        OR 
        transaction_items.item_name ILIKE city_commodities.item_name || ' %'
      )
  SQL

  subquery = select(
    'transactions.player_uuid AS player_uuid',
    'COALESCE(users.username, transactions.player_uuid) AS player_name',
    'SUM(transaction_items.weight) AS total_contribution',
    'city_commodities.category AS commodity_type',
    'MAX(transaction_items.created_at) AS last_transaction',
    'cities.name AS city_name'
  )
    .joins(:parent_transaction)
    .joins('INNER JOIN cities ON transactions.city_id = cities.id')
    .joins(fuzzy_join_sql)
    .joins('LEFT JOIN users ON transactions.player_uuid = users.minecraft_uuid')
    .where('transaction_items.created_at >= ?', start_date)
    
  # 3. Apply Filters Conditionally
  # ONLY filter by city if a city_id was actually passed
  subquery = subquery.where('transactions.city_id = ?', city_id) if city_id.present?
  subquery = subquery.where('transactions.shard_id = ?', shard_id) if shard_id.present?
  
  # 4. Group by clean category
  # This automatically sums up a player's metal sales from City 1 AND City 34
subquery = subquery.group('transactions.player_uuid, users.username, city_commodities.category, cities.name')

  # 5. Select the winner for each category
  from(subquery, 'ranked_contributions')
    .select('DISTINCT ON (commodity_type) *')
    .order('commodity_type, total_contribution DESC')
end


end
