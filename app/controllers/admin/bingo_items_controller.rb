module Admin
    class BingoItemsController < Admin::ApplicationController
    def index
      @bingo_items = BingoItem.order(created_at: :desc)
    end

    def new
      @bingo_item = BingoItem.new
    end

      def edit
        @bingo_item = BingoItem.find_by_id(params[:id])
      end
  

    def create
      @bingo_item = BingoItem.new(bingo_item_params)

      if @bingo_item.save
        # Logic to handle bulk item creation from the "content" textarea
        redirect_to admin_bingo_items_path, notice: 'Bingo Item created.'
      else
        render :new
      end
    end

      def update
        @bingo_item = BingoItem.find_by_id(params[:id])
        if @bingo_item.update(bingo_item_params)
           redirect_to edit_admin_bingo_item_path(@bingo_item), notice: 'Bingo Item was successfully updated.'
        end
      end


    private


    def bingo_item_params
      params.require(:bingo_item).permit(:content, :column_letter, :row_number)
    end
  end
end