# ImageUpload
# This module adds ajax upload functionalities to your controller.
# Require responds_to_parent plugin.
# ruby script/plugin install http://sean.treadway.info/svn/plugins/responds_to_parent/
module ImageUpload

  # extension for ActionController::Base
  module Extension
    module ClassMethods
      # class_name:: image attached model's class name
      # You can specify following options.
      # :starts_at:: Specify the starting points (methods as symbols) of uploading.
      # :tmp_dir:: The directory to store temporary files. The defaut is "#{RAILS_ROOT}/tmp/images".
      def image_upload(class_name, options = {})
        raise "class_name is required." unless class_name
        @image_attached_class_name = class_name

        options = {:tmp_dir => "#{RAILS_ROOT}/tmp/images"}.update(options)
        @image_upload_tmp_dir = options[:tmp_dir]
        # create directory
        FileUtils.makedirs(@image_upload_tmp_dir)
        self.__send__(:include, ImageUpload::Uploader)
        self.__send__(:before_filter, :clear_session_images, :only => options[:starts_at]) if options[:starts_at]
      end

      def image_attached_class_name
        @image_attached_class_name
      end
    end
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    private
    def send_stored_file(i)
      if i
        send_file i.stored_file_path, :filename => i.stored_name, :type => i.mime_type,
                        :stream => false, :disposition => 'inline'
      else
        render :nothing => true, :status => 404
      end
    end
  end

  # upload logics
  module Uploader
    module ClassMethods
      def image_upload_tmp_dir
        @image_upload_tmp_dir
      end
      def image_upload_actions
        [:session_image, :upload_session_image, :delete_session_image, :delete_stored_image]
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
      base.helper ImageUpload::Helper
    end


    MAX_TRY = 10
  
    # Display the temporary image file on the session.
    # params[:file_name] :: path of the temporary image file
    def session_image
      raise "no image in session" if !params[:file_name] || !(file = all_uploaded_files_on_session.detect{|f| f[:filename].rindex(params[:file_name])})
      send_file file[:filename], :filename => file[:filename], 
                      :stream => false, :disposition => 'inline', :type => file[:mime_type]
    end
        
    # Upload an image on the sesson temporary.
    # params[:uploaded_file_<name>]:: an uploaded file. <name> should be association_name.
    # params[:name]:: association_name
    def upload_session_image
      max_width = params[:width] || 120
      max_height = params[:height] || 120
      begin
        file = params["uploaded_file_#{params[:name]}".to_sym]
        logger.debug "file = #{file.inspect}"
        original_tmpfile = tmp_file_path(file.original_filename)
        File.open(original_tmpfile,"wb") do |f|
          f.write(file.read)
        end
        # Validate the original file
        @image_errors = []
        validate_image_type(original_tmpfile, params[:name])
        
        image_attached_class = eval(self.class.image_attached_class_name)
        validate_method_name = "validate_image_as_#{params[:name].singularize}".to_sym
        if image_attached_class.respond_to?(validate_method_name)
          errors = image_attached_class.send(validate_method_name, original_tmpfile)
          @image_errors.concat(errors) if errors.kind_of?(Array)
        end
        # TODO: deprecated.
        validate_image(original_tmpfile) if self.respond_to?(:validate_image)
        unless @image_errors.empty?
          File.delete(original_tmpfile)
          responds_to_parent do
            render :update do |page|
              page << "#{main_object_name(params[:name])}.refresh();"
              page.alert(@image_errors.join('\n'))
            end
          end
          return
        end

        modified_tmpfile = tmp_file_path(file.original_filename)
        if !resize_and_write_image(original_tmpfile, modified_tmpfile)
          modified_tmpfile = original_tmpfile
        end
        original_tmpname = cut_path(original_tmpfile) # file name
        modified_tmpname = cut_path(modified_tmpfile) # file name
        display_size, original_width, original_height, mime_type = ImageResize.use_image_size(modified_tmpfile) do |i|
          [ImageResize.get_reduction_size(i, max_width, max_height), i.get_width, i.get_height, i.mime_type]
        end
        uploaded_files_on_session(params[:name]) << {
          :filename => modified_tmpfile,
          :original_filename => file.original_filename,
          :session => true,
          :width => display_size[:width],
          :height => display_size[:height],
          :original_width => original_width,
          :original_height => original_height,
          :original_tmp_filename => original_tmpfile,
          :modified_angle => 0,
          :mime_type => mime_type
        }
        responds_to_parent do
          render :update do |page|
            image = {
              :original_filename => file.original_filename,
              :image_uri => url_for(:action => 'session_image', :file_name => modified_tmpname),
              :name => modified_tmpname,
              :session => true,
              :width => display_size[:width],
              :height => display_size[:height],
              :original_width => original_width,
              :original_height => original_height,
              :mime_type => mime_type
            }
            page << "#{main_object_name(params[:name])}.onUploaded(#{image.to_json});"
          end
        end
      rescue => e
        logger.error e
        logger.error e.backtrace.join("\n")
        responds_to_parent do        
          render :text => e.to_s
        end
      end
    end
    
    # params[:width]
    # params[:height]
    # params[:name]
    def rotate_session_image
      max_width = params[:width] || 120
      max_height = params[:height] || 120
      begin
        file_name = params[:file]
        if file_name && (file = all_uploaded_files_on_session.detect{|f| f[:filename].rindex(file_name)})
          if file[:filename] == file[:original_tmp_filename]
            file[:original_tmp_filename] = tmp_file_path(file[:original_filename]) if file[:filename] == file[:original_tmp_filename]
            FileUtils.mv(file[:filename], file[:original_tmp_filename])
          end
          require 'RMagick'
          img = ::Magick::Image::read(file[:original_tmp_filename]).first
          new_angle = (params[:angle].to_f + file[:modified_angle].to_f) % 360
          img.rotate!(new_angle)
          file[:modified_angle] = new_angle
          resize_image(img)
          img.write(file[:filename])
          img = nil
          enabled_gc = GC.enable
          GC.start
          GC.disable if enabled_gc
          display_size = ImageResize.use_image_size(file[:filename]) do |i|
            ImageResize.get_reduction_size(i, max_width, max_height)
          end
          file[:width] = display_size[:width]
          file[:height] = display_size[:height]
          modified_file_name = cut_path(file[:filename])
          render :update do |page|
            new_size = {
              :name => modified_file_name,
              :width => display_size[:width],
              :height => display_size[:height]
            }
            page << "#{main_object_name(params[:name])}.onRotated(#{new_size.to_json});"
          end

        end
      rescue => e
        logger.error e
        logger.error e.backtrace.join("\n")
        render :text=> "error"
      end
    end
    
    # Delete a image on the session.
    # params[:delete_file] :: the name of the temporary file to be deleted
    def delete_session_image
      begin
        file_name = params[:delete_file]
        if file_name && (file = all_uploaded_files_on_session.detect{|f| f[:filename].rindex(file_name)})
          delete_session_file(file)
        end
        render :text=> "success"
      rescue => e
        logger.error e
        render :text=> "error"
      end
    end
    
    # Put a stored image file's name on the deleting list.
    # params[:delete_file] :: The stored file name to be deleted
    # params[:name] :: Association Name
    def delete_stored_image
      deleted_files_on_session(params[:name]) << params[:delete_file] unless deleted_files_on_session(params[:name]).include?(params[:delete_file])
      render :text=> "success"
    end
    
    private

    def validate_image_type(file, association_name = nil)
      ImageResize.use_image_size(file) do |i|
        unless image_attached_class.image_permitted_types(association_name).include?(i.image_type)
          @image_errors << image_attached_class.image_type_error_message(association_name)
        end
      end
    end

    def resize_image(img)
      return false unless image_max_size
      return false if img.columns <= image_max_size[:width].to_i && img.rows <= image_max_size[:height]
      begin
        require 'RMagick'
        img.resize_to_fit!(image_max_size[:width].to_i, image_max_size[:height].to_i)
        return true
      rescue Exception => e
        return false
      end
    end

    def resize_and_write_image(source, dest)
      return false unless image_max_size
      begin
        result = true
        require 'RMagick'
        img = ::Magick::Image::read(source).first
        if resize_image(img)
          img.write(dest)
        else
          result = false
        end         
        img = nil
        enabled_gc = GC.enable
        GC.start
        GC.disable if enabled_gc        
        return result
      rescue Exception => e
        return false
      end
    end
    
    def search_session_file(files, filename)
      return nil if files == nil
      i = 0
      files.each do |file|
        return i if filename == cut_path(file[:filename])
        i += 1
      end
      nil
    end
    
    def tmp_file_path(filename)
      filename =~ /\.(.*)$/
      ext = $1
      ext = ".#{ext}" if ext
      n = 0
      salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
  
      begin
        raise if n == MAX_TRY
        tmp_filename = "#{self.class.image_upload_tmp_dir}/imgtmp.#{$$}.#{Time.now.strftime('%Y%m%d%H%M%S').crypt(salt).tr(' /.', '___')}.#{n}#{ext}"
        n += 1
      end while File.exist?(tmp_filename)
      return tmp_filename
    end
    
    def uploaded_files_on_session(association_name)
      session[:image_upload] ||= {}
      association_name = image_attached_class.image_association_name(association_name)
      image_attached_class.validate_image_association_name(association_name)
      session[:image_upload][association_name] ||= {}
      session[:image_upload][association_name][:uploaded_files] ||= []
      session[:image_upload][association_name][:uploaded_files]
    end

    def deleted_files_on_session(association_name)
      session[:image_upload] ||= {}
      association_name = image_attached_class.image_association_name(association_name)
      image_attached_class.validate_image_association_name(association_name)
      session[:image_upload][association_name] ||= {}
      session[:image_upload][association_name][:deleted_files] ||= []
      session[:image_upload][association_name][:deleted_files]
    end

    def set_images_to(obj, association_name = nil)
      raise "no obj" unless obj
      raise "not image_attached model" unless obj.class.image_attached?
      association_name = obj.class.image_association_name(association_name)

      uploaded_files_on_session(association_name).each{|tmp_file|
        obj.image_tmp_files(association_name) << {:path => tmp_file[:filename], :name => tmp_file[:original_filename], :original_tmp_path => tmp_file[:original_tmp_filename]}
      }
      
      deleted_files_on_session(association_name).each{|deleted_file_name|
        image = obj.find_image_by_stored_name(deleted_file_name, association_name)
        obj.deleted_images(association_name) << image if image
      }
    end
    
    def clear_session_images
      for uploaded_file in all_uploaded_files_on_session
        delete_session_file(uploaded_file)
      end
      session[:image_upload] = nil
    end
    
    def all_uploaded_files_on_session
      association_names = session[:image_upload] ? session[:image_upload].keys : []
      uploaded_files = []
      for association_name in association_names
        uploaded_files += uploaded_files_on_session(association_name)
      end
      uploaded_files
    end
    
    def image_max_size
      return image_attached_class.image_max_size
    end
    
    def image_attached_class
      @image_attached_class ||= eval(self.class.image_attached_class_name)
      @image_attached_class
    end
    
    def cut_path(path)
      path =~ /.+\/(.*)$/
      $1
    end
    
    # file:: file hash in session
    def delete_session_file(file)
      File::delete(file[:filename]) if File::exist?(file[:filename])
      File::delete(file[:original_tmp_filename]) if file[:original_tmp_filename] && File::exists?(file[:original_tmp_filename])
      if session[:image_upload]
        for association_name in session[:image_upload].keys
          break if image_upload_session(association_name)[:uploaded_files].delete(file)
        end
      end
    end
    
    def image_upload_session(association_name)
      session[:image_upload] ||= {}
      session[:image_upload][association_name] ||= {}
      session[:image_upload][association_name]
    end

  
  end
 
end
