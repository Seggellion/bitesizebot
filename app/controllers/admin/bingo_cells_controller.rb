# app/controllers/admin/bingo_cells_controller.rb
module Admin
  class BingoCellsController < Admin::ApplicationController # Ensure this matches your parent controller class
    def toggle
      @cell = BingoCell.find(params[:id])
      
      # Toggle the state
      @cell.update!(is_marked: !@cell.is_marked)

      # Handle side effects
      if @cell.is_marked?
        PendingAction.where(target: @cell, status: 'pending').update_all(status: 'approved')
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