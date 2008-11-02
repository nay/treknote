module MyPhotosHelper

  def my_photo_img_tag(photo, maxWidth, maxHeight, options = {})
    options = options.dup
    options[:align] = "middle"
    if photo.kind_of? FlickrPhoto
      options[:onload] = "wh = scale_down_size(#{maxWidth}, #{maxHeight}, this.naturalWidth, this.naturalHeight); this.width = wh.width; this.height = wh.height;"
      options[:class] = "fromFlickr"
      options[:alt] = photo.name
      return link_to(image_tag(photo.medium_url, options), photo.page_url)
    else
      w, h = photo.scale_down_size(maxWidth, maxHeight)
      options[:class] = "fromFile"
      options[:width] = w
      options[:height] = h
      options[:id] = "photo_#{photo.id}"
      url = my_photo_path(:id => photo.id)
      return link_to(image_tag(url, options), url)
    end
  end
end
