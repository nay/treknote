# The base stored file class.
class <%= class_name %> < ActiveRecord::Base
<% if parent_model.blank? -%>
  belongs_to :attachable, :polymorphic => true
  acts_as_list :scope => :attachable
<% else -%>
  belongs_to :<%= parent_model %>
  acts_as_list :scope => :<%= parent_model %>
<% end -%>

  attr_accessor :buffer, :tmp_file
  after_destroy :delete_file
  
  validates_presence_of :name<%= ', :unique_key' unless use_original_name %>
  
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
<% unless use_original_name -%>
    self.unique_key = genkey()
<% end -%>
  end

  # Returns true if the buffer is valid.
  def buffer?
    @buffer && @buffer != "" && @buffer.original_filename.length > 0
  end
  
  def tmp_file=(tmp_file)
    @tmp_file = tmp_file
    return unless @tmp_file
    self.name = tmp_file[:name]
<% unless use_original_name -%>
    self.unique_key = genkey()
<% end -%>
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
  
<% if use_original_name -%>
  def stored_name
    name
  end
<% end -%>

  protected

<% unless use_original_name -%>
  def before_save
    self.stored_name = create_file_name
  end
<% end -%>

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
  end

  private
<% unless use_original_name -%>
  # Create file_name from unique_key. 
  # Some file name (ex. using Japanese) can't be displayed properly by some OS.
  # And, this can disturb users to image and try other file names.
  def create_file_name(ext = nil)
    ext ||= self.ext
    return name unless ext
    "#{unique_key}.#{ext}"
  end
<% end -%>
  
  # Store the file in the file system.
  def store_buffer
    return unless buffer?
    @buffer.binmode
    File.open(stored_file_path, "w") do |f|
      f.binmode
      f.write(@buffer.read)
    end
  end
  
  # Delete the file from the file system.
  def delete_file
    File.delete(stored_file_path)
  end

  # You can overwrite this.    
  def path
    "#{RAILS_ROOT}/public/images/#{self.class.to_s.underscore.pluralize}"
  end

  <% unless use_original_name -%>

  GENKEY_MAX_TRY = 10

  def exsit_key?(key)
    <%= class_name %>.find(:first, :conditions => ['unique_key = ?', key]) ? true : false
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
  
  <% end -%>

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
