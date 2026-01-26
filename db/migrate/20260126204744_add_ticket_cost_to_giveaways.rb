class AddTicketCostToGiveaways < ActiveRecord::Migration[8.0]
  def change

add_column :giveaways, :ticket_cost, :integer, default: 1, null: false
    
    # Allow nulls to make checks optional
    change_column_null :giveaways, :min_karma, true
    change_column_null :giveaways, :min_fame, true

  end
end
