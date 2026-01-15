module Admin
    class PendingActionsController < ApplicationController

def index
    @actions = PendingAction.pending.includes(:user, :target)
  end

# app/controllers/admin/pending_actions_controller.rb
def bulk_approve
  # Only grab 'mark_cell' actions to avoid accidentally approving a win
  @actions = PendingAction.where(status: 'pending', action_type: 'mark_cell')
  
  ActiveRecord::Base.transaction do
    @actions.each do |action|
      # Update the cell
      action.target.update!(is_marked: true)
      # Update the action status
      action.update!(status: 'approved')
    end
  end

  redirect_to admin_bingo_games_path, notice: "Approved #{@actions.count} mark requests."
end


def update


    @action = PendingAction.find(params[:id])
    
    if params[:decision] == 'approve'
      @action.approve!
      flash[:notice] = "Action approved and applied."
    elsif params[:decision] == 'deny'
      @action.deny!
      flash[:alert] = "Action denied. User karma reduced."
    end

    redirect_to admin_pending_actions_path
  end


end
end