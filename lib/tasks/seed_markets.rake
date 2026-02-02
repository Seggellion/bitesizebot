# frozen_string_literal: true
namespace :db do
  namespace :seed do
    desc 'Seed Market Items'
    task markets: :environment do
      load Rails.root.join('db/seeds/markets.rb')
    end
  end
end
