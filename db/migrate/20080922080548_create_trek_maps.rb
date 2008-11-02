class CreateTrekMaps < ActiveRecord::Migration
  def self.up
    create_table :trek_maps do |t|
      t.integer :user_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :trek_maps
  end
end
