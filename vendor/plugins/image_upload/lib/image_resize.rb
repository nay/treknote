module ImageResize
  def self.use_image_size(file, &block)
    File::open(file, 'rb') do |fh|
      i = ImageSize.new(fh)
      result = yield i
      i.close # Added for windows
      return result
    end
  end

  def self.get_reduction_size(image_size, max_x, max_y)
    size = image_size.get_size
    return {:width => max_x, :height => max_y} if size == nil
    return reduction_size(max_x, max_y, size[:width], size[:height])
  end


  def self.reduction_size(max_x, max_y, x, y)
    h = y.to_f / max_y.to_f
    w = x.to_f / max_x.to_f
    return {:width => x.to_i, :height => y.to_i} if (h <= 1 and w <= 1)
    
    m = h >= w ? h : w
    return {:width => (x / m).to_i, :height => (y / m).to_i}
  end
end
