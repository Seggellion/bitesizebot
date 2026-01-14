# app/controllers/bingo_cards_controller.rb
class BingoCardsController < ApplicationController
  before_action :authenticate_user!

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
end