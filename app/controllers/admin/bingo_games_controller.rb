module Admin
    class BingoGamesController < Admin::ApplicationController
    def index
      @bingo_games = BingoGame.order(created_at: :desc)
      @actions = PendingAction.pending.includes(:user, :target)

@current_game = BingoGame.active.first # 
@last_winner = @bingo_games.where.not(winner: nil).last&.winner&.username
  @total_games = BingoGame.count
  @total_participants = User.joins(:bingo_cards).distinct.count
  @most_frequent_player = User.joins(:bingo_cards)
                              .group(:id)
                              .order('count(bingo_cards.id) DESC')
                              .first

  # Bingo Card Logic
  @active_cards = @current_game&.bingo_cards&.includes(bingo_cells: :bingo_item) || []
  @potential_winners = @active_cards.select { |card| card.verify_win && !card.won? }
  @claimed_winner = @current_game&.winner # Assumes a winner association exists

    end

    def new
      @bingo_game = BingoGame.new
    end

      def edit
        @bingo_game = BingoGame.find_by_id(params[:id])
      end
  

      # app/controllers/admin/bingo_games_controller.rb
def start
  @bingo_game = BingoGame.find(params[:id])
  
  if @bingo_game.update(status: "active", started_at: Time.current)
    redirect_to admin_bingo_game_path(@bingo_game), notice: "Bingo Game is now active!"
  else
    redirect_to admin_bingo_game_path(@bingo_game), alert: "Failed to start game."
  end
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