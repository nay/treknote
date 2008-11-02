class FlickrPhoto < Photo
  def base_url
    "http://farm#{flickr_farm}.static.flickr.com/#{flickr_server}/#{flickr_photo_id}_#{flickr_secret}_"
  end
  def small_url
    base_url + "s.jpg"
  end
  def thumbnail_url
    base_url + "t.jpg"
  end
  def medium_url
    base_url + "m.jpg"
  end
  def large_url
    base_url + "b.jpg"
  end
  def page_url
    "http://www.flickr.com/photos/#{user.flickr_id}/#{flickr_photo_id}"
  end
end

