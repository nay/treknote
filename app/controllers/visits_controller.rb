class VisitsController < UserContentsController
  before_filter :load_map
  before_filter :load_visit, :only => [:show]
  
  stylesheet 'visits'
  
  def show
    redirect_to notes_path(:visit_id => @visit.id)
  end
  
  # 検索結果や年別表示
  def index
    if params[:year]
      @visits = @map.visits.in_year(params[:year]).paginate(:page => params[:page], :per_page => 10)
      @what = "#{params[:year]}年の記録"
    elsif params[:keyword]
      @what = "「#{params[:keyword]}」を含む記録"
      keywords = params[:keyword].split(' ')
      if keywords.empty?
        @visit = []
      else
        @visits = @map.visits.contains(keywords).paginate(:page => params[:page], :per_page => 10)
      end
    else
      @visits = @map.visits.paginate(:page => params[:page], :per_page => 10)
    end
    @title = "「#{@map.name}」の#{@what}"    
  end
  
  # 特定のマップのスポットをVisit付きで返す。汎用性が低いためこのコントローラにいれる
  def spots
    visits = @map.visits
    # spot_id で振り分ける
    hash = {}
    for v in visits
      hash[v.spot_id] ||= []
      hash[v.spot_id] << v
    end
    @spots = []
    stored_spots = Spot.find(*hash.keys)
    stored_spots = [stored_spots] unless stored_spots.kind_of?(Array)
    for s in stored_spots
      @spots << {:spot => s, :visits => hash[s.id]}
    end
    respond_to do |format|
      format.json { render :json => @spots.to_json(:except => [:created_at, :updated_at]) }
    end
  end
  
  protected
  def default_url_options(options = nil)
    if options && @map
      case options[:controller]
        when 'maps'
          return {:url_name => @target_user.url_name, :id => @map.id}
        when 'photo'
          return {:url_name => @target_user.url_name, :map_id => @map.id}
      end
    end
    return {}
  end
  
  private
  def load_visit
    super :id
  end
end
