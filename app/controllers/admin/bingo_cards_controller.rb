module Admin
    class BingoCardsController < Admin::ApplicationController
    def index
      @bingo_cards = BingoCard.order(created_at: :desc)
    end

    def new
      @bingo_card = BingoCard.new
    end

      def edit
        @bingo_card = BingoCard.find_by_id(params[:id])
      end
  

    def create
      @bingo_card = BingoCard.new(bingo_card_params)

      if @bingo_card.save
        # Logic to handle bulk item creation from the "content" textarea
        redirect_to admin_bingo_cards_path, notice: 'Bingo Item created.'
      else
        render :new
      end
    end

      def update
        @bingo_card = BingoCard.find_by_id(params[:id])
        if @bingo_card.update(bingo_card_params)
           redirect_to edit_admin_bingo_card_path(@bingo_card), notice: 'Bingo Item was successfully updated.'
        end
      end

      # app/controllers/bingo_cards_controller.rb
def show
  @bingo_card = BingoCard.find(params[:id])
  @game = @bingo_card.bingo_game
  
  # Grouping cells for the grid display
  @grouped_cells = @bingo_card.bingo_cells
                              .includes(:bingo_item)
                              .order(:id)
                              .group_by { |c| c.bingo_item.column_letter }
end

       
      def destroy
        @bingo_card = BingoCard.find(params[:id])
        @bingo_card.destroy
        redirect_to admin_bingo_card_path, notice: 'Page was successfully deleted.'
      end

    private


    def bingo_card_params
      params.require(:bingo_card).permit(:content, :column_letter, :row_number)
    end
  end
end