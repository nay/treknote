require 'gd2'
class FilePhoto < Photo
  attr_accessor :buffer, :tmp_file
  after_destroy :delete_file
  
  validates_presence_of :unique_key
  
  MAX_WIDTH = 800
  MAX_HEIGHT = 800
  
  def ext
    self.name =~ /.*\.(.*)$/
    $1
  end

  # Set the uploaded buffer.
  # This is useful for uploading without Ajax I/F.  
  def buffer=(buffer)
    @buffer = buffer
    return unless buffer?
    self.name = buffer.original_filename
    self.unique_key = genkey()
  end

  # Returns true if the buffer is valid.
  def buffer?
    @buffer && @buffer != "" && @buffer.original_filename.length > 0
  end
  
  def tmp_file=(tmp_file)
    @tmp_file = tmp_file
    return unless @tmp_file
    self.name = tmp_file[:name]
    self.unique_key = genkey()
  end

  # You can change this if you want to use another name pattern.
  def stored_file_path
    File.join(path, stored_name)
  end
  
  def image_path
    return $1 if stored_file_path.match(/public\/images\/(.*)$/)
    return $1 if stored_file_path.match(/public(\/.*)$/)
    nil
  end

  def scale_down_size(max_width, max_height)
    return [nil, nil] unless self.width && self.height
    h = height.to_f / max_height.to_f
    w = width.to_f / max_width.to_f
    return [self.width, self.height] if (h <= 1 && w <= 1)
    
    m = h >= w ? h : w
    return [(self.width.to_f / m).to_i, (self.height.to_f / m).to_i]
  end
  

  protected
  def validate
    i = ImageSize.new(@buffer)
    begin
      logger.info("image_type = #{i.image_type}")
      errors.add_to_base("JPEGファイル、PNGファイルしか保存できません。") unless [:JPEG, :PNG].include?(i.image_type)
    ensure
      @buffer.pos = 0 # TODO: なんか頭が落ちるので！
    end
  end    

  def before_save
    self.stored_name = create_file_name
  end

  def before_create
    if @tmp_file
      File::open(@tmp_file[:path], 'rb') do |fh|
        update_file_attributes(i = ImageSize.new(fh))
        i.close # for windows
      end
    else
      update_file_attributes(ImageSize.new(@buffer))
    end
  end
  
  def after_create
    FileUtils.makedirs(path) unless File.exist?(path)
    if @tmp_file
      FileUtils.mv(@tmp_file[:path], stored_file_path)
      raise "Couldn't move #{@tmp_file[:path]}" unless File.exist?(stored_file_path)
      # delete original tmp file (if exists)
      File.delete(@tmp_file[:original_tmp_path]) if @tmp_file[:original_tmp_path] && File.exist?(@tmp_file[:original_tmp_path])
      @tmp_file = nil
    else
      store_buffer
      @buffer.close # Avoid TempFile's garbage collection problem (exception arount closed stream).
      @buffer = nil
    end
    begin
      resize
    rescue => e
      logger.error(e)
      p e
      p e.backtrace
      raise e
    end
  end

  private
  
  def resize
    w, h = scale_down_size(MAX_WIDTH, MAX_HEIGHT)
    resized = false
#    ImageScience.with_image(stored_file_path) do |img|
#      if img.width > MAX_WIDTH || img.height > MAX_HEIGHT
#        img.resize(w, h) do |new_image|
#          new_image.save("#{stored_file_path}.tmp")
#        end
#        resized = true
#      end
#    end
    format = nil
    if self.mime_type == "image/jpeg"
      format = :jpeg
    elsif self.mime_type == "image/png"
      format = :png
    elsif /(png)/i =~ self.ext
      format = :png      
    elsif /(jpg|jpeg)/i =~ self.ext
      format = :jpeg
    else
      raise "could not get format"
    end
    GD2::Image.import(stored_file_path, :format => format) {|img| 
      if img.width > MAX_WIDTH || img.height > MAX_HEIGHT
        img.resize!(w, h)
        img.export("#{stored_file_path}.tmp", :format => format)
        resized = true
      end
    }

    if resized
      FileUtils.rm(stored_file_path)
      FileUtils.mv("#{stored_file_path}.tmp", stored_file_path)
    end
  end
  
  
  # Create file_name from unique_key. 
  # Some file name (ex. using Japanese) can't be displayed properly by some OS.
  # And, this can disturb users to image and try other file names.
  def create_file_name(ext = nil)
    ext ||= self.ext
    return name unless ext
    "#{unique_key}.#{ext}"
  end
  
  # Store the file in the file system.
  def store_buffer
    return unless buffer?
    @buffer.binmode
    @buffer.pos = 0 # TODO: なんか頭が落ちるので！
    File.open(stored_file_path, "wb") do |f|
      f.write(@buffer.read)
    end
  end
  
  # Delete the file from the file system.
  def delete_file
    begin
      File.delete(stored_file_path)
    rescue => e
      logger.error("Could not delete #{stored_file_path}. Ignored.")
      logger.error(e)
    end
  end

  # You can overwrite this.    
  def path
    "#{RAILS_ROOT}/photos/#{self.visit.user_id}/#{self.visit_id}"
    
#    "#{RAILS_ROOT}/public/images/#{self.class.to_s.underscore.pluralize}"
  end

  
  GENKEY_MAX_TRY = 10

  def exsit_key?(key)
    Photo.find(:first, :conditions => ['unique_key = ?', key]) ? true : false
  end


  def genkey
    salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
    n = 0
    key = nil
    begin
      raise "genkey_max_try over." if n == GENKEY_MAX_TRY
      key = "#{Time.now.strftime('%Y%m%d%H%M%S').crypt(salt).tr(' /.', '___')}-#{n}"
      n += 1
    end while exsit_key?(key)
    key
  end
  
  
  def update_file_attributes(image_size)
    raise "no ImageSize" unless image_size
    self.mime_type = image_size.mime_type
    if size = image_size.get_size
      self.width = size[:width]
      self.height = size[:height]
    else
      self.width = nil
      self.height = nil
    end
  end  

end
