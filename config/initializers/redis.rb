# config/initializers/redis.rb
if Rails.env.production?
  # Create a global constant instead of using the deprecated Redis.current
  REDIS = Redis.new(
    url: ENV['REDIS_URL'], 
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  )
end