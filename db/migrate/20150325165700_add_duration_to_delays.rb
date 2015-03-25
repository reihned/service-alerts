class AddDurationToDelays < ActiveRecord::Migration
  def change
    add_column :delays, :duration, :integer
  end
end
