class NotesController < UserContentsController
  before_filter :load_map, :load_visit
  before_filter :load_note, :only => [:show]
  
  stylesheet 'notes', 'notes-ie'
  
  def index
    @title = visit_formal_name @visit
  end
  
  def show
    @title = note_subject_or_default @note
  end
  
  
  protected
  def default_url_options(options = nil)
    
    if options
      case options[:controller]
        when 'maps'
          return {:url_name => @target_user.url_name, :id => @map.id}
        when 'my_visits'
          return {:map_id => @map.id, :id => @visit.id}
        when 'my_maps'
          return {:id => @map.id}
      end
    end
    return {}
  end
  
  private
  def load_note
    @note = @visit.notes.find(params[:id])
  end
end
