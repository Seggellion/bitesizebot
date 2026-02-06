class LastEnabledAt < ActiveRecord::Migration[8.0]
  def change
    add_column :system_settings, :last_enabled_at, :datetime
  end
end
