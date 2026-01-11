class AccountController < ApplicationController

def show
    @page = Page.find_by_slug('account')            

@purchase_transactions =
  Transaction.where(player_uuid: current_user.minecraft_uuid, transaction_type: 'purchase')
             .order(created_at: :desc)

@sell_transactions =
  Transaction.where(player_uuid: current_user.minecraft_uuid, transaction_type: 'sell')
             .order(created_at: :desc)

    @contributions = TransactionItem.user_contributions(@current_user.minecraft_uuid)


    render "pages/account"
end

def login
    @page = Page.find_by_slug('login')
    render "pages/login"

end

end