class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos, :force => true do |t|
      t.column "type",            :string,   :limit => 40
      t.column "position",        :integer
      t.column "name",            :text
      
      t.column "stored_name",     :text
      t.column "unique_key",      :string,   :limit => 32
      t.column "visit_id", :integer
      t.column "mime_type",       :string,   :limit => 40
      t.column "width",           :integer
      t.column "height",          :integer
      t.column "created_at",      :datetime
      t.column "updated_at",      :datetime
    end
  end

  def self.down
    drop_table :photos
  end
end
