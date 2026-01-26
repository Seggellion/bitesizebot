class MonthlyBingoDrawService
  def self.call
    # 1. Define the Timebox (Past 30 Days)
    start_date = 30.days.ago
    end_date = Time.current

    # 2. Get Raw Pool: Unique users who won a bingo game in this window
    raw_winners = User.joins(:won_games)
                      .where(bingo_games: { 
                        status: 'ended', 
                        ended_at: start_date..end_date 
                      })
                      .distinct

    # 3. Identify Exclusions (Banned Tags & Recent Winners)
    banned_tag = Tag.find_by(name: 'giveaway_banned')
    banned_ids = banned_tag ? Tagging.where(tag: banned_tag, taggable_type: 'User').pluck(:taggable_id) : []
    
    # "Recent winners" (Users who won any giveaway in the last 6 months)
    recent_winner_ids = User.recent_winners(6.months).pluck(:id)

    # 4. Filter to get the final eligible pool
    eligible_pool = raw_winners.reject do |user|
      banned_ids.include?(user.id) || recent_winner_ids.include?(user.id)
    end

    # 5. Perform the Draw Transaction
    # We use a transaction so if anything fails (e.g., database error), nothing is saved.
    result = ActiveRecord::Base.transaction do
      
      # A. Create the parent Giveaway record
      giveaway = Giveaway.create!(
        title: "Monthly Bingo Draw - #{Time.current.strftime('%B %Y')}",
        giveaway_type: :bingo,
        ticket_cost: 0,
        status: :open, # Temporarily open while we add entries
        created_at: Time.current
      )

      # B. Create Entry Records for every eligible user
      # This provides the "paper trail" the analyst wants.
      eligible_pool.each do |user|
        giveaway.giveaway_entries.create!(
          user: user,
          tickets_count: 1 # Standard 1 ticket per qualifier
        )
      end

      # C. Select the Winner
      winner = nil
      if eligible_pool.any?
        winner = eligible_pool.sample
        
        # D. Finalize the Giveaway
        giveaway.update!(
          winner: winner,
          status: :completed,
          drawn_at: Time.current
        )
        
        # E. Trigger the Announcement (using the method inside your Giveaway model)
        # We use 'send' because announce_winner_to_twitch is private
        giveaway.send(:announce_winner_to_twitch) rescue nil
      else
        # If no one qualified, we close it without a winner
        giveaway.update!(status: :closed)
      end

      # Return a structure with all data needed for the dashboard/logs
      OpenStruct.new(
        success: true,
        giveaway: giveaway,
        winner: winner,
        total_pool_size: raw_winners.count,
        eligible_count: eligible_pool.count,
        banned_count: raw_winners.count { |u| banned_ids.include?(u.id) },
        recent_win_excluded_count: raw_winners.count { |u| recent_winner_ids.include?(u.id) }
      )
    end

    result
  rescue StandardError => e
    # Log the error and return a failure object
    Rails.logger.error("MonthlyBingoDrawService Error: #{e.message}")
    OpenStruct.new(success: false, error: e.message)
  end
end