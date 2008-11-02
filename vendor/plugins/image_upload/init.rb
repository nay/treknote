# Include hook code here
require 'image_upload'
require 'image_upload_helper'
require 'image_size'
require 'image_resize'
ActionController::Base.send(:include, ImageUpload::Extension)
ActionController::Base.send(:helper, ImageUpload::ViewerHelper)
require 'image_attached'
ActiveRecord::Base.send(:include, ImageUpload::ImageAttached::Extension)
