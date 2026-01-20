web: bundle exec rails server -p $PORT
worker: bundle exec sidekiq -C config/sidekiq.yml & sleep 5 && bundle exec rails runner "TwitchWebsocketListener.run"