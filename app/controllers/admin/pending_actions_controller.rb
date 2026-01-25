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

def approve_similar
  @action = PendingAction.find(params[:id])
  target_coord = @action.request_coordinate

  if target_coord.blank?
    redirect_back fallback_location: admin_dashboard_path, alert: "Could not determine coordinate."
    return
  end

  game = @action.bingo_game
  game&.remember_coordinate!(target_coord, approved_by: @action.user)

  similar_requests = PendingAction.pending
                                  .where(action_type: 'mark_cell')
                                  .select { |pa| pa.request_coordinate == target_coord }

  count = similar_requests.count

  ActiveRecord::Base.transaction do
    similar_requests.each(&:approve!)
  end

  respond_to do |format|
    format.html { redirect_back fallback_location: admin_dashboard_path, notice: "Approved #{count} requests for #{target_coord}!" }
    format.turbo_stream { flash.now[:notice] = "Approved #{count} requests for #{target_coord}!" }
  end
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