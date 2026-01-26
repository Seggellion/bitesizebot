module Admin
  class GiveawaysController < Admin::ApplicationController
    before_action :set_giveaway, only: [:show, :edit, :update, :destroy, :close, :draw, :reroll]
    before_action :load_dashboard_stats, only: [:show]

    # GET /admin/giveaways
    def index
      # If we hit index, we want to show the dashboard for the "current" giveaway
      # logic for determining "current" is in set_giveaway_context
      set_giveaway_context
      
      if @giveaway
        load_dashboard_stats
        render :index
      else
        redirect_to new_admin_giveaway_path
      end
    end

    # GET /admin/giveaways/:id
    def show
      # @giveaway is set by before_action :set_giveaway
    end

    def new
      @giveaway = Giveaway.new(min_karma: 0, min_fame: 0)
    end

    def create
      @giveaway = Giveaway.new(giveaway_params)
      if @giveaway.save
              redirect_to admin_giveaways_path, notice: "Giveaway was Created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @giveaway.update(giveaway_params)
        redirect_to admin_giveaway_path(@giveaway), notice: "Giveaway updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @giveaway.destroy
      redirect_to admin_giveaways_path, notice: "Giveaway was deleted."
    end

    def close
      @giveaway.closed!
      redirect_to admin_giveaway_path(@giveaway), notice: "Entries are now locked."
    end

    def draw
      winner = @giveaway.draw_winner!
      handle_winner_redirect(winner)
    end

    def reroll
      # Logic: Reset current winner and draw again
      if @giveaway.giveaway_entries.count > 0
      @giveaway.update(winner_id: nil, status: :closed)
        winner = @giveaway.draw_winner!
        handle_winner_redirect(winner, reroll: true)
      else
        redirect_to admin_giveaway_path(@giveaway), alert: "Cannot reroll: No entries found."
      end
    end

    private

    # Smart logic to determine which giveaway to show
    def set_giveaway
      @giveaway = Giveaway.find(params[:id])
    end

    # Used for Index to find the "Best" giveaway to show if no ID provided
    def set_giveaway_context
      # 1. Look for an active one
      @giveaway = Giveaway.where(status: :open).last 
      # 2. Fallback to the most recent one (even if closed)
      @giveaway ||= Giveaway.last 
    end

    def load_dashboard_stats
      return unless @giveaway

      # Stats for the specific giveaway being viewed
      @total_tickets = @giveaway.giveaway_entries.sum(:tickets_count)
      @unique_users = @giveaway.giveaway_entries.count
      @avg_tickets_per_user = @unique_users.positive? ? (@total_tickets.to_f / @unique_users).round(2) : 0
      
      # Filter calculation
      @karma_floor_impact = User.where("karma < ?", @giveaway.min_karma).count
      
      # New viewers calculation
      @new_participants = @giveaway.giveaway_entries
                                   .where(created_at: @giveaway.created_at..)
                                   .joins(:user)
                                   .where('users.created_at > ?', 1.day.ago)
                                   .count
      
      @entries = @giveaway.giveaway_entries.includes(:user).order(created_at: :desc)
      
      # Load history for the sidebar/bottom list
      @all_giveaways = Giveaway.order(created_at: :desc)
    end

    def handle_winner_redirect(winner, reroll: false)
      if winner
        # Optional: Add Turbo Stream broadcast here if you want real-time updates for viewers
        msg = reroll ? "Rerolled! New winner is #{winner.username}" : "Winner drawn: #{winner.username}"
        redirect_to admin_giveaway_path(@giveaway), notice: msg
      else
        redirect_to admin_giveaway_path(@giveaway), alert: "No eligible winners found."
      end
    end

    def giveaway_params
      params.require(:giveaway).permit(:title, :giveaway_type, :min_karma, :min_fame, :max_entries_per_user, :ticket_cost)
    end
  end
end