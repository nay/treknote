class MapsController < UserContentsController
  before_filter :load_map, :only => [:show]
  
  stylesheet 'maps'
  
  def show
    @title = @map.name
    # TODO: trek_map に保存されたものがあればそれを表示する！
    @g_map = GMap::WORLD
    
  end
  
  protected
  def default_url_options(options = nil)
    if options
      case options[:controller]
        when 'photos', 'visits'
          return {:url_name => @target_user.url_name, :map_id => @map.id}
      end
    end
    return {}
  end
  
  
  private
  def load_map
    super :id
  end
end
