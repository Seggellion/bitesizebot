web: bundle exec rails server -p $PORT
worker: bundle exec sidekiq & bundle exec rails runner "TwitchWebsocketListener.run"