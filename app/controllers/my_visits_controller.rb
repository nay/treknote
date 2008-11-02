# ログインした人が自分のVisitを編集するためのコントローラ
class MyVisitsController < ApplicationController
  before_filter :login_required
  before_filter :load_map
  before_filter :load_visit, :only => [:edit, :update, :edit_photos, :edit_photos_from_flickr, :edit_photos_from_file, :show, :edit_notes, :destroy, :remember_edit_photos_status]

  stylesheet 'my_visits'

  # my_map/1/visits で Ajax 用の部分htmlを返す
  def index
    render :partial => 'shared/visits', :locals => {:visits => @map.visits.paginate(:page => params[:page], :per_page => 10)}
  end
  
  # 行ったことのある場所を登録する
  def new
    @spot = Spot.new
    @visit = Visit.new
    @g_map = GMap::WORLD
  end
  
  def create
    @visit = @map.visits.build(params[:visit])
    @visit.spot = Spot.find_or_initialize_by_name_and_latitude_and_longitude(params[:spot][:name], params[:spot][:latitude].to_f, params[:spot][:longitude].to_f)
    @visit.save!
    flash[:notice] = "「#{ERB::Util.h(@visit.spot.name)}」の記録を登録しました。"
    redirect_to edit_photos_my_visit_path(:map_id => @map.id, :id => @visit.id, :mode => 'continue')
  end
  
  def edit
    @g_map = GMap.new(@visit.spot.latitude_str, @visit.spot.longitude_str, 15)
    @spot = @visit.spot
  end
  
  def update
    @visit.attributes = params[:visit]
    @visit.spot = Spot.find_or_initialize_by_name_and_latitude_and_longitude(params[:spot][:name], params[:spot][:latitude].to_f, params[:spot][:longitude].to_f)
    @visit.save!
    flash[:notice] = "「#{ERB::Util.h(@visit.spot.name)}」の記録を変更しました。"
    if params[:mode] == 'continue'
      redirect_to edit_photos_my_visit_path(:mode => params[:mode])
    else
      redirect_to my_visit_path
    end
  end
  
  # tab = file / flickr, page = x (flickrの場合のみ有効）をつけてリクエストすることもできる
  def edit_photos
    if session[:edit_photos_status] && session[:edit_photos_status][@visit.id.to_sym]
      h = session[:edit_photos_status][@visit.id.to_sym]
      @tab = h[:tab]
      @page = @tab == :flickr ? h[:page] : nil
    end
    @tab ||= :file

    @my_photos_page = params[:include] ? @visit.photos.page_including(params[:include]) : 1
  end
  
  def remember_edit_photos_status
    session[:edit_photos_status] ||= {}
    session[:edit_photos_status][@visit.id.to_sym] ||= {}
    h = session[:edit_photos_status][@visit.id.to_sym]
    h[:tab] = params[:tab] == 'flickr' ? :flickr : :file
    h[:page] = params[:page] if h[:tab] == :flickr
    render :nothing => true
  end
  
  def edit_photos_from_flickr
    render :partial => 'from_flickr'
  end

  def edit_photos_from_file
    render :partial => 'from_file'
  end

  def edit_notes
    if @visit.notes.empty?
      @note = @visit.notes.build
    else
      @note = @visit.notes.last
    end
  end

  def show
    # 同じ場所の訪問リンク
    prev = nil
    current_user.visits.to_spot(@visit.spot).find(:all, :order => "visited_on").each do |v|
      if v == @visit
        @prev_visit_to_the_spot = prev
      elsif prev == @visit
        @next_visit_to_the_spot = v
      end
      prev = v
    end
    
    # 近い時期(前後3日以内)の記録リンク
    prev = nil
    current_user.visits.visited_around(@visit.visited_on).find(:all, :order => "visited_on").each do |v|
      if v == @visit
        @prev_visit_then = prev
      elsif prev == @visit
        @next_visit_then = v
      end
      prev = v
    end
  end
  
  def destroy
    @visit.destroy
    flash[:notice] = "記録を削除しました。"
    redirect_to my_map_path
  end
  
  protected
  def default_url_options(options = nil)
    if options
      case options[:controller]
        when 'my_photos', 'my_notes'
          return {:map_id => @map.id, :visit_id => @visit.id}
        when 'notes', 'photos'
          return {:url_name => current_user.url_name, :map_id => @map.id, :visit_id => @visit.id}
        when 'my_maps'
          return {:id => @map.id}
      end
    end
    return {}
  end
  
  private
  def load_map
    @map = current_user.maps.find(params[:map_id])
  end
  def load_visit
    @visit = @map.visits.find(params[:id])
  end

end
