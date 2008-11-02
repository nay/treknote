class ImageUploadGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      args_clone = args.clone
      use_original_name = args_clone.delete('use_original_name')
      parent_model = args_clone.first
      # Check for class naming collisions.
      m.class_collisions class_path, class_name

      # Controller, helper, views, and test directories.
      m.directory File.join('app/models', class_path)
      m.directory 'app/controllers'
      m.directory 'app/helpers'
      m.directory 'test/functional'
      m.directory File.join('test/unit', class_path)
      m.directory 'public/images'

      m.template 'stored_file.rb',
                  File.join('app/models',
                            class_path,
                            "#{singular_name}.rb"),
                            :assigns => {:parent_model => parent_model, :use_original_name => use_original_name}
      m.template 'wait.gif',
                  File.join('public/images', class_path, 'wait.gif')
      m.template 'rotate.gif',
                  File.join('public/images', class_path, 'rotate.gif')

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate',
          :assigns => {
            :migration_name => "Create#{@table_name}",
            :parent_model => parent_model,
            :use_original_name => use_original_name            
          }, :migration_file_name => "create_#{@table_name}"
      end
    end
  end

end
