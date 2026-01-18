# app/controllers/bingo_cards_controller.rb
class BingoCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card

  def show
  end


  
  # app/controllers/bingo_cards_controller.rb
def claim_win
  @bingo_card = current_user.bingo_cards.find(params[:id])
  @game = @bingo_card.bingo_game
  @message = BingoService.request_win(current_user, @game)

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.prepend("flash-messages", 
        html: "<div class='alert alert-info'>#{@message}</div>".html_safe)
    end
    format.html { redirect_to @bingo_card, notice: @message }
  end
end


def replace_card
    @card = current_user.bingo_cards.find(params[:id])
    
  if @card.bingo_game.status != 'invite'
    redirect_back fallback_location: root_path, alert: "The market is closed. The game has already started!"
    return
  end

    # Check limit before attempting transaction
    if @card.replacement_count >= 2
      redirect_back fallback_location: root_path, alert: "You have reached the replacement limit."
      return
    end

    if @card.replace_card!(2000)
      redirect_back fallback_location: root_path, notice: "Your card has been replaced! 2,000 currency deducted."
    else
      # Pull the error from the model (likely 'insufficient funds')
      alert_msg = @card.errors.full_messages.to_sentence
      redirect_back fallback_location: root_path, alert: alert_msg
    end
  end



  def mark_cell
    @bingo_card = current_user.bingo_cards.find(params[:id])
    @game = @bingo_card.bingo_game
    
    # Extract letter and number from the coordinate (e.g., "B12")
    # match(/(^[A-Z])(\d+)/) splits "B12" into ["B", "12"]
    match = params[:coordinate].match(/(^[a-zA-Z])(\d+)/)
    
    if match
      col_letter = match[1]
      row_num = match[2]
      
      # Call your existing logic
      @message = BingoCard.request_mark(current_user, @game, col_letter, row_num)
    else
      @message = "Invalid coordinate format."
    end

    respond_to do |format|
      format.turbo_stream # This will look for mark_cell.turbo_stream.erb
      format.html { redirect_to @bingo_card, notice: @message }
    end
  end


def set_card
    @card = current_user.bingo_cards.find(params[:id])
  end

end