class AddFlickrInfoToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :flickr_photo_id, :string
    add_column :photos, :flickr_secret, :string
    add_column :photos, :flickr_server, :string
    add_column :photos, :flickr_farm, :string
  end

  def self.down
    remove_column :photos, :flickr_photo_id
    remove_column :photos, :flickr_secret
    remove_column :photos, :flickr_server
    remove_column :photos, :flickr_farm
  end
end
