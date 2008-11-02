class PhotosController < UserContentsController
  before_filter :load_map, :load_visit
  before_filter :load_photo, :only => [:show]
  
  stylesheet 'photos'
  
  # アルバムビュー
  def index
    @title = "#{visit_short_name @visit}のアルバム"
    
  end
  
  def show
    send_stored_file(@photo)
  end
  
  protected
  def default_url_options(options = nil)
    if options && @visit
      case options[:controller]
        when 'my_visits'
          return {:map_id => @map.id, :id => @visit.id}
      end
    end
    return {}
  end
  
  
  private
  def load_photo
    @photo = @visit.photos.find(params[:id])
  end
  
end
