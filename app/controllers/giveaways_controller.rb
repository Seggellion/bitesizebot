class GiveawaysController < ApplicationController
  

  def join
    @giveaway = Giveaway.find(params[:id])
    amount = params[:amount].to_i
    amount = 1 if amount <= 0

    # We reuse the logic from our Twitch Service
    result = GiveawayService.handle_entry(current_user, @giveaway, amount)

    if result.is_a?(String) && result.include?("added")
      redirect_to '/giveaways', notice: result
    else
      redirect_to '/giveaways', alert: result
    end
  end

end