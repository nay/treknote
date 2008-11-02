# This module would be included in ActiveRecord::Base.
module ImageUpload
  module ImageAttached
    module Extension
      module ClassMethods
        # options
        # * :class_name
        # * :foreign_key
        # * :polymorphic
        # * :size
        # * :name
        # * :max_size
        # * :types
        # * :type_error_message
        # * :conditions
        def image_attached(options = {})
          # merge to default options
          options = {:size => 1, :class_name => 'StoredFile', :types => [:JPEG, :PNG, :GIF], :type_error_message => "Please upload jpg/png/gif image files.", :polymorphic => true}.update(options)
          @image_settings ||= {}

          # determine association_name
          slot_size = options[:size].to_i
          raise ":size must be larger than 0." if slot_size < 1
          options = {:name => slot_size == 1 ? :image : :images}.update(options)
          association_name = options[:name].to_sym
          
          # the first definition is used as a default name.
          @image_default_association_name ||= association_name
          
          @image_settings[association_name] = {}
          settings = @image_settings[association_name]
          
          # set options into settings
          settings[:class_name] = options[:class_name] # @image_class_name
          settings[:slot_size] = slot_size # @image_slot_size
          settings[:max_size] = options[:max_size] ? options[:max_size].clone : nil # @image_max_size
          settings[:permitted_types] = options[:types].map{|t| t.to_s.upcase.to_sym} # @image_permitted_types
          settings[:type_error_message] = options[:type_error_message] # @image_type_error_message
          if settings[:max_size]
            raise "Rmagick is required for the max_size option of image_attached in #{self.to_s}. " unless require_rmagick
            raise "max_size must be defined :width and :height" if !settings[:max_size][:width] || !settings[:max_size][:height]
            raise "width must be larger than 0" if settings[:max_size][:width].to_i <= 0
            raise "height must be larger than 0" if settings[:max_size][:height].to_i <= 0
          end
          stored_association_name = ("stored_" + association_name.to_s).to_sym
          if slot_size == 1
            association_options = {:class_name => settings[:class_name], :dependent => :destroy}
            association_options[:as] = :attachable if options[:polymorphic]
            association_options[:foreign_key] = options[:foreign_key] if options[:foreign_key]
            association_options[:conditions] = options[:conditions] if options[:conditions]
            self.__send__(:has_one, stored_association_name, association_options)
            self.__send__(:attr_writer, association_name)
            eval(<<EOS
              self.__send__(:define_method, :#{association_name}) do
                @#{association_name} ||= self.#{stored_association_name} unless image_sources(association_name)[:association_deleted]
                @#{association_name}
              end
EOS
)
          else
            association_options = {:class_name => settings[:class_name], :order => 'position', :dependent => :destroy}
            association_options[:as] = :attachable if options[:polymorphic]
            association_options[:foreign_key] = options[:foreign_key] if options[:foreign_key]
            association_options[:conditions] = options[:conditions] if options[:conditions]
            self.__send__(:has_many, stored_association_name, association_options)
            self.__send__(:attr_writer, association_name)
            eval(<<EOS
              self.__send__(:define_method, :#{association_name}) do
                @#{association_name} ||= #{stored_association_name}.clone
                @#{association_name}
              end
EOS
)
          end
          
          self.__send__(:include, ImageUpload::ImageAttached::Model) unless image_attached?
        end
        
        def require_rmagick
          begin
            require 'RMagick'
            return true
          rescue Exception => e
            return false
          end
        end
        
        def image_attached?
          include?(ImageUpload::ImageAttached::Model)
        end

        def image_association_name(association_name = nil)
          association_name ? association_name.to_sym : image_default_association_name
        end
        
        def valid_image_association_name?(association_name)
          image_association_names.include?(association_name)
        end
        
        def validate_image_association_name(association_name)
          raise "The image association name '#{association_name}' is not defined by image_attached." unless valid_image_association_name?(association_name)
        end
        
        def image_settings(association_name = nil)
          @image_settings ||= {}
          association_name = image_association_name(association_name)
          settings = @image_settings[association_name] || image_super_attr(:image_settings, association_name)
          raise "The image association name '#{association_name}' is not defined by image_attached." unless settings
          settings
        end
        
        def image_class_name(association_name = nil)
          image_settings(association_name)[:class_name] || image_super_attr(:image_class_name)
        end
        
        def image_max_size(association_name = nil)
          image_settings(association_name)[:max_size] || image_super_attr(:image_max_size)
        end
        
        def image_permitted_types(association_name = nil)
          image_settings(association_name)[:permitted_types] || image_super_attr(:image_permitted_types)
        end
        
        def image_permitted_exts(association_name = nil)
          image_permitted_types(association_name).map{|type| image_type_to_exts(type)}.flatten
        end
        
        def image_type_error_message(association_name = nil)
          image_settings(association_name)[:type_error_message] || image_super_attr(:image_type_error_message)
        end

        def image_super_attr(attr, *args)
          if superclass && superclass.include?(ImageUpload::ImageAttached::Model)
            return superclass.send(attr, *args)
          else
            return nil
          end
        end
        
        private
        def image_type_to_exts(type)
          case type
          when :JPEG
            return ['jpg', 'jpeg']
          when :TIFF
            return ['tif', 'tiff'] 
          when :OTHER
            return '*'
          else
            return type.to_s.downcase
          end
        end
      end
      def self.included(base)
        base.extend(ClassMethods)
      end
    end
    module Model
      module ClassMethods
        def image_slot_size(association_name = nil)
          image_settings(association_name)[:slot_size] || image_super_attr(:image_slot_size)
        end
        
        def image_association_names
          super_names = image_super_attr(:image_association_names) || []
          return super_names unless @image_settings
          super_names + @image_settings.keys
        end
        
        def image_default_association_name
          # super first
          image_super_attr(:image_default_association_name) || @image_default_association_name
        end
                
      end
      def self.included(base)
        base.extend(ClassMethods)
        base.before_validation_on_create :prepare_images_on_create
        base.before_validation_on_update :prepare_images_on_update
        base.after_save :save_images, :clear_tmp_images
      end
      
      def image_sources(association_name = nil)
        @image_sources ||= {}
        association_name = self.class.image_association_name(association_name)
        self.class.validate_image_association_name(association_name)
        @image_sources[association_name] ||= {}
        @image_sources[association_name]
      end
      
      def image_tmp_files(association_name = nil)
        image_sources(association_name)[:tmp_files] ||= []
        image_sources(association_name)[:tmp_files]
      end
      
      def deleted_images(association_name = nil)
        image_sources(association_name)[:deleted_images] ||= []
        image_sources(association_name)[:deleted_images]
      end
      
      def find_image_by_stored_name(stored_name, association_name = nil)
        association_name = self.class.image_association_name(association_name)
        if self.class.image_slot_size(association_name) == 1
          i = __send__(association_name)
          i && i.stored_name == stored_name ? i : nil
        else
          __send__(association_name).detect{|i| i.stored_name == stored_name}
        end
      end
      
      def reload_images
        for association_name in self.class.image_association_names
          stored_association_name = "stored_#{association_name}".to_sym
          __send__(stored_association_name, true)
          __send__("#{association_name}=".to_sym, nil)
          image_sources(association_name)[:association_deleted] = nil
        end
      end
      
      private
      def prepare_images_on_create
        for association_name in self.class.image_association_names
          send("#{association_name}=".to_sym, nil)
        end
        create_images
      end
      
      def prepare_images_on_update
        for association_name in self.class.image_association_names
          send("#{association_name}=".to_sym, nil)
        end
        for association_name in self.class.image_association_names
          if self.class.image_slot_size(association_name) == 1
            unless deleted_images(association_name).empty?
              __send__("#{association_name}=".to_sym, nil)
              image_sources(association_name)[:association_deleted] = true
            end
          else
            # need to use id because association_name is not real association
            deleted_ids = deleted_images(association_name).map{|i| i.id}
            __send__(association_name).reject!{|i| deleted_ids.include?(i.id)}
          end
        end
        create_images
      end
      
      def create_images
        for association_name in self.class.image_association_names
          if self.class.image_slot_size(association_name) == 1
            unless image_tmp_files(association_name).empty?
              image_class = eval(self.class.image_class_name(association_name))
              image_attributes = {:tmp_file => image_tmp_files(association_name).first}
              image_instance = self.respond_to?("new_#{association_name}".to_sym) ? self.send("new_#{association_name}".to_sym, image_attributes) : image_class.new(image_attributes)
              self.send("#{association_name}=".to_sym, image_instance)
            end
          else
            image_class = eval(self.class.image_class_name(association_name))
            # need to update because acts_as_lists has updated positions
            image_tmp_files(association_name).each{|tmp_file|
              image_attributes = {:tmp_file => tmp_file}
              image_instance = self.respond_to?("new_#{association_name}".to_sym) ? self.send("new_#{association_name}".to_sym, image_attributes) : image_class.new(image_attributes)
               __send__(association_name) << image_instance
            }
          end
        end
      end
      
      def save_images
        for association_name in self.class.image_association_names
          stored_association_name = "stored_#{association_name}".to_sym
          __send__("#{stored_association_name}=".to_sym, __send__(association_name))
          if self.class.image_slot_size(association_name) == 1
            __send__(stored_association_name).save! if __send__(stored_association_name)
          else
            __send__(stored_association_name).each{|i| i.save! }
          end
        end
      end
      
      def clear_tmp_images
        @image_sources = nil
      end
    
    end
    
  end

end