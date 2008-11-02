module PhotosHelper
  
  def photo_img_tag(photo, maxWidth, maxHeight, options = {}, url_options = {})
    options = options.dup
    if photo.kind_of? FlickrPhoto
      options[:onload] = "wh = scale_down_size(#{maxWidth}, #{maxHeight}, this.naturalWidth == undefined ? this.width : this.naturalWidth, this.naturalHeight == undefined ? this.height : this.naturalHeight); this.width = wh.width; this.height = wh.height;"
      options[:class] = "fromFlickr"
      options[:alt] = photo.name
      url =  maxWidth <= 75 && maxHeight <= 75 ? photo.small_url : photo.medium_url
      return link_to(image_tag(url, options), photo.page_url)
    else
      w, h = photo.scale_down_size(maxWidth, maxHeight)
      options[:class] = "fromFile"
      options[:width] = w
      options[:height] = h
      options[:id] = "photo_#{photo.id}"
      url = photo_path({:id => photo.id}.merge(url_options))
      return link_to(image_tag(url, options), url)
    end
  end
end
