class CreateVisits < ActiveRecord::Migration
  def self.up
    create_table :visits do |t|
      t.integer :user_id
      t.integer :spot_id
      t.integer :trek_map_id
      t.date :visited_on

      t.timestamps
    end
  end

  def self.down
    drop_table :visits
  end
end
