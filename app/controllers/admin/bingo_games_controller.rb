module Admin
  class BingoGamesController < Admin::ApplicationController
    before_action :set_bingo_game, only: [:edit, :update, :start, :destroy]
    skip_before_action :authenticate_user!, if: -> { action_name == 'overlay' }

    def index
      @bingo_games = BingoGame.order(created_at: :desc)
      @actions = PendingAction.pending.includes(:user, :target)
      @current_game = BingoGame.current_or_latest

      @last_winner = @bingo_games.where.not(winner: nil).last&.winner&.username
      @total_games = BingoGame.count
      @total_participants = User.joins(:bingo_cards).distinct.count
      @most_frequent_player = User.joins(:bingo_cards)
                                  .group(:id)
                                  .order('count(bingo_cards.id) DESC')
                                  .first

      @active_cards = @current_game&.bingo_cards&.includes(bingo_cells: :bingo_item) || []
      @claimed_winner = @current_game&.winner
    end

    def new
      @bingo_game = BingoGame.new
    end

    def create
      @bingo_game = BingoGame.new(bingo_game_params)
      @bingo_game.host = current_user
      
      if @bingo_game.save
        redirect_to admin_bingo_games_path, notice: "Bingo Game created successfully!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # set_bingo_game handles finding the record
    end

    def update
      # Check if status is changing to 'active' to set the started_at timestamp
      if bingo_game_params[:status] == 'active' && @bingo_game.status != 'active'
        @bingo_game.started_at = Time.current
      end

      if @bingo_game.update(bingo_game_params)
        # The model callbacks (broadcast_status_change, etc.) handle the Turbo Stream pushes
        redirect_to admin_bingo_games_path, notice: "Game updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def start
      if @bingo_game.update(status: "active", started_at: Time.current)
        redirect_to admin_bingo_games_path, notice: "Bingo Game is now live!"
      else
        redirect_to admin_bingo_games_path, alert: "Failed to start game."
      end
    end

    def destroy
      @bingo_game.destroy
      redirect_to admin_bingo_games_path, notice: "Game and associated cards were deleted."
    end

    def overlay
      @current_game = BingoGame.current_or_latest
      render template: "admin/bingo_games/overlay", layout: false
    end

    private

    def set_bingo_game
      @bingo_game = BingoGame.find(params[:id])
    end

    def bingo_game_params
      # Added :status to permit the dropdown selection from the form
      params.require(:bingo_game).permit(:title, :size, :status)
    end
  end
end