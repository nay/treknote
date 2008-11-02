module ImageUpload
module ViewerHelper
  # image:: an image model object
  # url_options:: options for url_for to show image
  # html_options:: html_options for img tag
  # default_image:: name of default image file (under public/images). default is nil (not be used).
  def stored_image_tag(image, url_options = {}, html_options = {}, default_image = nil)
    html_options = {:width => 120, :height => 120}.update(html_options)
    if image
      width, height = image.scale_down_size(html_options[:width], html_options[:height])
      html_options[:width] = width if width
      html_options[:height] = height if height
      if ipath = image.image_path
        return image_tag(ipath, html_options)
      else
        options = html_options.update({:src => url_for(url_options)})
        return tag("img", options)
      end
    elsif default_image
      return image_tag(default_image, html_options)
    else
      return "<span>no image</span>"
    end
  end
end
module Helper
  # options
  # :name:: image association name
  # :width:: max width of the image area
  # :height:: max height of the image area
  # :form_id:: the id of the form element
  # :url ::(optional)
  # :delete_caption:: the caption for the delete button 
  # :permitted_exts:: The regular expression of permitted file exts. Default is 'jpg|jpeg|png|gif'.
  # :ext_error_message:: The error message for file ext check.
  # :template_extension:: The JavaScript Code to extend templates. 
  # function xxx(file) {
  # }
  def image_upload_field(image_attached, options = {}, html_options = {}, &block)
    options = {:name => image_attached.class.image_default_association_name, :width => 120, :height => 120, :form_id => 'form', :delete_caption => 'Delete', :rotate => false, :rotating_angle => 90}.update(options)
    raise "RMagick is required for the :rotate => true of image_upload_field." if options[:rotate] && !image_attached.class.require_rmagick
    files = [image_attached.__send__(options[:name])].flatten.compact
    files.reject!{|image| image.new_record?}
    url = options[:url] || url_for(:controller => controller.controller_name, :action => "upload_session_image",:name => options[:name], :width => options[:width], :height => options[:height], :escape => false)
    r = ""
    permitted_exts = image_attached.class.image_permitted_exts(options[:name])
    if permitted_exts.include?('*')
      exts_pattern = '.*'
    else
      exts_pattern = "\.(#{permitted_exts.reject{|e| e == '*'}.join('|')})$"
    end
    r << ajax_ui(files, url, options, exts_pattern, image_attached.class.image_type_error_message(params[:name]), &block)
    r << "#{main_object_name(options[:name])} = new #{main_class_name(options[:name])}(#{init_image(files, options[:width], options[:height], options[:name], &block).to_json}, #{image_attached.class.image_slot_size(params[:name])});\n"
    r = javascript_tag r
    
    r << upload_form(options, html_options)
  end

  private
  
  def main_object_name(association_name)
    'imageUpload' + association_name.to_s.camelize
  end
  
  def main_class_name(association_name)
    'ImageUpload' + association_name.to_s.camelize
  end

  
  def ajax_ui(files, upload_url, options, permitted_exts, ext_error_message, &block)
    form_id = options[:form_id]
    association_name = options[:name]
    on_upload = [options[:on_upload]].flatten.compact
    add_upload_handlers = ""
    on_upload.each {|code|
      add_upload_handlers += <<EOS
        this.onUploadHandler.push(function(){
          #{code}
        });
EOS
    }
   on_delete = [options[:on_delete]].flatten.compact
   add_delete_handlers = ""
   on_delete.each {|code|
     add_delete_handlers += <<EOS
       this.onDeleteHandler.push(function(){
         #{code}
       });
EOS
   }
   
    csrf_token_add_param = "param += '&#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}');" if defined?(request_forgery_protection_token)
    r = <<-EOJ
var #{main_class_name(association_name)} = Class.create();
#{main_class_name(association_name)}.prototype = {
  initialize: function(files, max) {
    this.imageFiles = files;
    this.maxImage = max;
    this.onUploadHandler = new Array;
    #{add_upload_handlers}
    this.onDeleteHandler = new Array;
    #{add_delete_handlers}
    Event.observe(window, 'load', this.main.bind(this), false);
  },
  onChange: function() {
    var file = $('uploaded_file_#{options[:name]}').value;
    if (file == '') return;
    if (!file.toLowerCase().match(/#{permitted_exts}/)) {
      alert("#{ext_error_message}");
      $('uploaded_file_#{options[:name]}').value = '';
      return;
    }
    var actn = $('#{form_id}').action;
    var trgt = $('#{form_id}').target;
    $('#{form_id}').action = '#{upload_url}';
    $('#{form_id}').target = 'image_frame_#{options[:name]}';
    $('#{form_id}').submit();
    $('#{form_id}').action = actn;
    $('#{form_id}').target = trgt;
    Element.hide("uploaded_file_#{options[:name]}");
    this.wait();
  },
  wait: function() {
    var wait = $('wait_image_#{options[:name]}');
    wait.src = "#{image_path('wait.gif')}";
    Element.show(wait);
  },
  showImage: function() {
    var last = this.imageFiles.length - 1;
    var image = 'entry_image_#{options[:name]}_' + last;
    new Effect.Appear(image, { from: 0, duration: 0.5 });
  },
  onUploaded: function(file) {
    this.imageFiles.push(file);
    this.refresh();
    for (var i =0; i < this.onUploadHandler.length; i++) {
      this.onUploadHandler[i].call();
    }
  },
  onRotated: function(size) {
    for (var i = 0; i < this.imageFiles.length; i++) {
      imageFile = this.imageFiles[i];
      if (imageFile.name == size.name) {
        imageFile.width = size.width;
        imageFile.height = size.height;
        imageElement = $('entry_image_#{options[:name]}_' + i.toString());
        imageElement.width = imageFile.width;
        imageElement.height = imageFile.height;
        var mark = '&';
        if (imageFile.image_uri.lastIndexOf('?')==-1) {
          mark = '?';
        }
        imageElement.src = imageFile.image_uri + mark + 'p=' + (new Date()).getTime().toString();
        break;
      }
    }
  },
  createImgTag: function(i) {
    var mark = '&';
    if (this.imageFiles[i].image_uri.lastIndexOf('?')==-1) {
      mark = '?';
    }
    imgfile = this.imageFiles[i].image_uri + mark + 'p=' + (new Date()).getTime().toString();
    if (typeof(this.imageFiles[i].width) == 'undefined' || this.imageFiles[i].width == null) {
      img_width = '';
    } else {
      img_width = this.imageFiles[i].width.toString();
    }
    if (typeof(this.imageFiles[i].height) == 'undefined' || this.imageFiles[i].height == null) {
      img_height = '';
    } else {
      img_height = this.imageFiles[i].height.toString();
    }
    if (i == (this.imageFiles.length -1)) {
      style = 'display: none';
    } else {
      style = '';
    }
    return '<img id="entry_image_#{options[:name]}_' + i.toString() + '" style="' + style + '" src="' + imgfile + '" width="' + img_width + '" height="' + img_height + '"/>'
  },
  createHtml: function() {
    var r = '';
    var template = '';
    for (var i = 0; i < this.imageFiles.length; i++) {
      template = $('upload_image_template_#{options[:name]}').innerHTML;
      template = template.replace(/%%img%%/g, this.createImgTag(i));
      template = template.replace(/%%count%%/g, i.toString());
      template = template.replace(/%%original_filename%%/g, this.imageFiles[i].original_filename);
      template = template.replace(/%%original_width%%/g, this.imageFiles[i].original_width);
      template = template.replace(/%%original_height%%/g, this.imageFiles[i].original_height);
      template = template.replace(/%%mime_type%%/g, this.imageFiles[i].mime_type);
      r += template;
    }
    if (this.maxImage > this.imageFiles.length) {
      template = $('upload_form_template_#{options[:name]}').innerHTML;
      template = template.replace(/%%count%%/g, this.imageFiles.length.toString());
      template = template.replace(/%%template%%/g, '');
      r += template;
    }
    return r;
  },
  refresh: function() {
    $('image_contenner_#{options[:name]}').innerHTML = this.createHtml();
    if (this.maxImage > this.imageFiles.length) {
      Event.observe("uploaded_file_#{options[:name]}", "change", this.onChange.bind(this), false);
    }
    this.addDeleteButton();
    #{'this.addRotateButton();' if options[:rotate]}
    if (this.imageFiles.length < 1) return;
    var image = $('entry_image_#{options[:name]}_' + (this.imageFiles.length - 1));
    if (image.complete) {
      this.showImage();
    } else {
      Event.observe(image, "load", this.showImage.bind(this), false);
    }
  },
  #{rotating_functions(options)}
  addDeleteButton: function() {
    for (var i = 0; i < this.imageFiles.length; i++) {
      var btn = $('delete_button_#{options[:name]}_' + i);
      Event.observe(btn, "click", this.deleteImage.bind(this, i), false);
    }
  },
  deleteImage: function(count) {
    var image = $('entry_image_#{options[:name]}_' + count);
    new Effect.Fade(image, { from: 0, duration: 0.5, afterFinish: this.onAfterDelete.bind(this, count)});
  },
  onAfterDelete: function(count) {
    var url = "#{url_for(:action => 'delete_session_image')}";
    if (!this.imageFiles[count].session) {
      url = "#{url_for(:action => 'delete_stored_image', :name => association_name)}"
    }
    var param = "delete_file=" + this.imageFiles[count].name;
    #{csrf_token_add_param}
    this.imageFiles = this.deleteArray(this.imageFiles, count);
    new Ajax.Request(
      url, 
      {method: 'post', parameters: param, onComplete: this.onDeleteImage.bind(this)}
    );
    this.refresh();
    for (var i =0; i < this.onDeleteHandler.length; i++) {
      this.onDeleteHandler[i].call();
    }
  },
  onDeleteImage: function() {
  },
  deleteArray: function(o, index) {
    r = new Array();
    for (var i = 0; i < o.length; i++) {
      if (i == index) continue;
      r.push(o[i]);
    }
    return r;
  },
  main: function() {
    this.refresh();
  }
};
EOJ
  end

  def rotating_functions(options)
    return '' unless options[:rotate]
    csrf_token_add_param = "param += '&#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}');" if defined?(request_forgery_protection_token)
    <<EOT
  addRotateButton: function() {
    for (var i = 0; i < this.imageFiles.length; i++) {
      var btn = $('rotate_button_#{options[:name]}_' + i);
      if (this.imageFiles[i].session) {
        Event.observe(btn, "click", this.rotateImage.bind(this, i), false);
      } else {
        $("rotate_button_#{options[:name]}_" + i).style.display = "none";
      }
    }
  },
  rotateImage: function(count) {
    var url = "#{url_for(:action => 'rotate_session_image')}";
    var param = "file=" + this.imageFiles[count].name + "&angle=#{options[:rotating_angle]}&width=#{options[:width]}&height=#{options[:height]}&name=#{options[:name]}";
    #{csrf_token_add_param}
    new Ajax.Request(
      url, 
      {method: 'post', parameters: param, onComplete: this.onImageRotated.bind(this)}
    );
    return false;
  },
  onImageRotated: function() {
  },
EOT
  end

  def upload_form(options, html_options)
    input_field_options = html_options.merge(:type => "file", :name => "uploaded_file_#{options[:name]}", :id => "uploaded_file_#{options[:name]}%%template%%")
    rotate_button = "<a id='rotate_button_#{options[:name]}_%%count%%'>#{image_tag('rotate.gif', :border => 0)}</a>" if options[:rotate]
    r = <<EOS
<div id="image_contenner_#{options[:name]}"></div>
<iframe id="image_frame_#{options[:name]}" name="image_frame_#{options[:name]}"></iframe>
#{javascript_tag('if (navigator.appVersion.match(/Konqueror|Safari|KHTML/)) {$("image_frame_' + options[:name].to_s + '").style.height = "1px";} else {$("image_frame_' + options[:name].to_s + '").style.display = "none";}')}
<div id="upload_image_template_#{options[:name]}" style="display: none;">
<div>
  %%img%%
  <input id="delete_button_#{options[:name]}_%%count%%" type="button" value="#{options[:delete_caption]}"/>
  #{rotate_button}
  #{options[:template_extension]}
  <br />
</div>
</div>
<div id="upload_form_template_#{options[:name]}" style="display: none;">
<div>
  <img id="wait_image_#{options[:name]}%%template%%" style="display: none;" />
  #{tag("input", input_field_options)}
</div>
</div>
EOS
  end

  def init_image(files, max_width, max_height, association_name, &block)
    r = []
    n = nil
    r.concat n if (n = get_attached_images(files, max_width, max_height, association_name, &block)) != nil
    r.concat n if (n = get_session_images(image_upload_session(association_name)[:uploaded_files], max_width, max_height)) != nil
    logger.debug(r.to_json)
    return r
  end
  
  def get_session_images(files, max_width, max_height)
    return nil if files == nil || files.size == 0
    r = []
    files.each do |file|
      file[:filename] =~ /.*\/(.*)$/
      hash = image_hash(file[:filename], url_for(:action => 'session_image', :file_name => $1), max_width, max_height, true, file[:original_filename])
      r << hash if hash
    end
    r
  end
  
  def get_attached_images(files, max_width, max_height, association_name, &block)
    return nil if files == nil || files.size == 0
    r = []
    files.each do |file|
      if block_given?
        url = yield file
      else
        if ipath = file.image_path
          url = image_path(ipath)
        else
          logger.warn("Please use image_upload_field with url block.")
          url = "#"
        end
      end
      next if image_upload_session(association_name)[:deleted_files] && image_upload_session(association_name)[:deleted_files].include?(file.stored_name)
      hash = image_hash(file.stored_file_path, url, max_width, max_height, false, file.name, file.stored_name)
      r << hash if hash
    end
    r
  end
  
  def image_upload_session(association_name)
    return {} unless session[:image_upload]
    session[:image_upload][association_name] || {}
  end
  
  # Create a resource hash of JavaScript ImageFile object.
  # image_path:: the path of image file
  # url:: the url to display the image
  # file_name:: The file name that users can see. Generated from image_path if this option is not specified.
  # original_filename:: the original file name
  def image_hash(image_path, url, max_width, max_height, in_session, original_filename, file_name = nil)
    unless file_name
      image_path =~ /.*\/(.*)$/
      file_name = $1
    end
    return nil unless File::file?(image_path) # error handling is required at caller side
    size, original_width, original_height, mime_type = ImageResize.use_image_size(image_path) {|i| [ImageResize.get_reduction_size(i, max_width, max_height), i.get_width, i.get_height, i.mime_type]}
    return {
      :original_filename => original_filename,
      :name => file_name,
      :image_uri => url,
      :session => in_session,
      :width => size[:width],
      :height => size[:height],
      :original_width => original_width,
      :original_height => original_height,
      :mime_type => mime_type
    }
  end
end
end
