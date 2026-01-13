module Admin
    class PendingActionsController < ApplicationController

def index
    @actions = PendingAction.pending.includes(:user, :target)
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