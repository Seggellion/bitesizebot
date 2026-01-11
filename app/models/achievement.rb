# app/models/activity.rb
class Achievement < ApplicationRecord
    belongs_to :user
  self.inheritance_column = :_type_disabled



end