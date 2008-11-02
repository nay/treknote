class AddVisitsCountToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :visits_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :spots, :visits_count
  end
end
