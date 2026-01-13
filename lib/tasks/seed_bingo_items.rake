# frozen_string_literal: true
namespace :db do
  namespace :seed do
    desc 'Seed Bingo Items'
    task bingo_items: :environment do
      load Rails.root.join('db/seeds/bingo_items.rb')
    end
  end
end
