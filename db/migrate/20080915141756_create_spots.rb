class CreateSpots < ActiveRecord::Migration
  def self.up
    create_table :spots do |t|
      t.decimal :latitude, :precision => 19, :scale => 16
      t.decimal :longitude, :precision => 19, :scale => 16
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :spots
  end
end
