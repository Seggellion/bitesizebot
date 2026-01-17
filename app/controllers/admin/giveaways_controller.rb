module Admin
    class GiveawaysController < Admin::ApplicationController
  before_action :set_giveaway, only: [:index, :show, :close, :draw]

def show

end

  def new
  @giveaway = Giveaway.new(min_karma: 0, min_fame: 0)
end

def create

  @giveaway = Giveaway.new(giveaway_params)
  if @giveaway.save
    redirect_to admin_giveaways_path, notice: "Giveaway '#{@giveaway.title}' is now LIVE!"
  else
    render :new, status: :unprocessable_entity
  end
end

  def index
    @total_tickets = @giveaway.giveaway_entries.sum(:tickets_count)
    @unique_users = @giveaway.giveaway_entries.count
    @avg_tickets_per_user = @unique_users.positive? ? (@total_tickets.to_f / @unique_users).round(2) : 0
    @karma_floor_impact = User.where("karma < ?", @giveaway.min_karma).count # Potential users blocked
    @new_participants = @giveaway.giveaway_entries.where(created_at: @giveaway.created_at..).joins(:user).where('users.created_at > ?', 1.day.ago).count
    
    @entries = @giveaway.giveaway_entries.includes(:user).order(created_at: :desc)
  end

  def close
    @giveaway.closed!
    redirect_to admin_giveaway_path(@giveaway), notice: "Entries are now locked."
  end

  def draw
    winner = @giveaway.draw_winner!
    if winner
      # Broadcast the win to the public view via Turbo Streams
      @giveaway.broadcast_replace_to "giveaway_#{@giveaway.id}", 
                                     target: "giveaway_status", 
                                     partial: "admin/giveaways/winner_banner", 
                                     locals: { winner: winner }
      
      redirect_to admin_giveaway_path(@giveaway), notice: "Winner drawn: #{winner.username}"
    else
      redirect_to admin_giveaway_path(@giveaway), alert: "No eligible winners found."
    end
  end

  private

  def set_giveaway
    @giveaway = Giveaway.last
  end

  def giveaway_params
  params.require(:giveaway).permit(:title, :giveaway_type, :min_karma, :min_fame, :max_entries_per_user)
end

end
end