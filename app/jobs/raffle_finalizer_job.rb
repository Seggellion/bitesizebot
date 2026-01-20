class RaffleFinalizerJob < ApplicationJob
  queue_as :default

  def perform(raffle_id, bid, type)
    raffle = Raffle.find_by(id: raffle_id)
    return unless raffle && raffle.status == 'active'

    case type
    when 'warning_30'
      RaffleService.announce(bid, "⏳ 30 SECONDS LEFT!")
    when 'warning_15'
      RaffleService.announce(bid, "⚠️ 15 SECONDS!")
    when 'finalize'
      RaffleService.finalize_raffle(raffle, bid)
    end
  end
end