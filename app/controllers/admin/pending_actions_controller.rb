module Admin
    class PendingActionsController < ApplicationController

def index
    @actions = PendingAction.pending.includes(:user, :target)
  end

# app/controllers/admin/pending_actions_controller.rb
def bulk_approve
  # Only grab 'mark_cell' actions to avoid accidentally approving a win
  actions = PendingAction.where(status: 'pending', action_type: 'mark_cell').to_a
  approved_count = 0

  ActiveRecord::Base.transaction do
    actions.each do |action|
      next unless action.reload.status == 'pending'

      action.approve!
      approved_count += 1
    end
  end

  redirect_to admin_bingo_games_path, notice: "Approved #{approved_count} mark requests."
end

def approve_similar
  @action = PendingAction.find(params[:id])
  unless @action.target.is_a?(BingoCell)
    redirect_back fallback_location: admin_dashboard_path, alert: "Action does not target a bingo cell."
    return
  end

  game = @action.bingo_game
  bingo_item = @action.target.bingo_item

  if game.blank? || bingo_item.blank?
    redirect_back fallback_location: admin_dashboard_path, alert: "Could not determine bingo item."
    return
  end

  similar_requests = PendingAction.pending
                                  .where(
                                    action_type: 'mark_cell',
                                    target_type: 'BingoCell',
                                    target_id: game.bingo_cells.where(bingo_item_id: bingo_item.id).select(:id)
                                  )

  count = similar_requests.count

  ActiveRecord::Base.transaction do
    @action.approve!
  end

  respond_to do |format|
    format.html { redirect_back fallback_location: admin_dashboard_path, notice: "Approved #{count} requests for #{bingo_item.content}!" }
    format.turbo_stream { flash.now[:notice] = "Approved #{count} requests for #{bingo_item.content}!" }
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
