# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081004074309) do

  create_table "notes", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.integer  "user_id"
    t.integer  "visit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.string   "type",            :limit => 40
    t.integer  "position"
    t.text     "name"
    t.text     "stored_name"
    t.string   "unique_key",      :limit => 32
    t.integer  "visit_id"
    t.string   "mime_type",       :limit => 40
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "flickr_photo_id"
    t.string   "flickr_secret"
    t.string   "flickr_server"
    t.string   "flickr_farm"
  end

  create_table "spots", :force => true do |t|
    t.decimal  "latitude",     :precision => 19, :scale => 16
    t.decimal  "longitude",    :precision => 19, :scale => 16
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visits_count",                                 :default => 0, :null => false
  end

  create_table "trek_maps", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "url_name"
    t.string   "flickr_id"
  end

  create_table "visits", :force => true do |t|
    t.integer  "user_id"
    t.integer  "spot_id"
    t.integer  "trek_map_id"
    t.date     "visited_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
