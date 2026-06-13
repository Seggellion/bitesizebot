# app/controllers/api/utility_controller.rb
module Api
  class UtilityController < ApplicationController
    # Skip CSRF verification if you are testing via Postman or simple JS fetch calls
    skip_before_action :verify_authenticity_token, raise: false

    def trigger_tick
      # CRITICAL: Prevent players from manually advancing the market in production!
      if Rails.env.production?
        render json: { error: "Forbidden: Cannot manually trigger ticks in production environment." }, status: :forbidden
        return
      end

      # Call the master method directly. This processes synchronously.
      MarketService.tick

      render json: { 
        success: true, 
        message: "Market tick forced successfully! Prices updated and orders processed." 
      }, status: :ok
    rescue => e
      render json: { 
        success: false, 
        error: e.message 
      }, status: :unprocessable_entity
    end
  end
end