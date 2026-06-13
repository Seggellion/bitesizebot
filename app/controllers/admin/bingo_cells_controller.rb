# app/controllers/admin/bingo_cells_controller.rb
module Admin
  class BingoCellsController < Admin::ApplicationController # Ensure this matches your parent controller class
    def toggle
      @cell = BingoCell.find(params[:id])

      if @cell.is_marked?
        @cell.update!(is_marked: false)
      else
        @cell.bingo_game.claim_item!(
          @cell.bingo_item,
          approved_by: current_user,
          coordinate: @cell.coordinate
        )
      end

      # Since we are moving to Model Broadcasts, we just redirect or head :ok
      # The broadcast will handle the UI update asynchronously.
      respond_to do |format|
        format.html { redirect_back(fallback_location: admin_bingo_games_path) }
        format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") } # distinct fallback
      end
    end
  end
end
