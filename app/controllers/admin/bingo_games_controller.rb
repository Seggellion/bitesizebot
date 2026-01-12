module Admin
    class BingoGamesController < Admin::ApplicationController
    def index
      @bingo_games = BingoGame.order(created_at: :desc)
    end

    def new
      @bingo_game = BingoGame.new
    end

      def edit
        @bingo_game = BingoGame.find_by_id(params[:id])
      end
  

    def create
      @bingo_game = BingoGame.new(bingo_game_params)
      @bingo_game.host = current_user

      if @bingo_game.save
        # Logic to handle bulk item creation from the "content" textarea
        process_items(params[:bingo_items_text])
        redirect_to admin_bingo_games_path, notice: 'Bingo Game created.'
      else
        render :new
      end
    end

    private

    def process_items(text)
      return if text.blank?
      text.split("\n").map(&:strip).reject(&:empty?).each do |phrase|
        @bingo_game.bingo_items.create(content: phrase)
      end
    end

    def bingo_game_params
      params.require(:bingo_game).permit(:title, :size)
    end
  end
end