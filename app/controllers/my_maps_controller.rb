class MyMapsController < ApplicationController
  before_filter :login_required
  before_filter :load_map, :only => [:show, :destroy, :edit, :update]
  
  stylesheet 'my_maps'
  
  # マイページ
  def index
    @maps = current_user.maps.paginate(:page => params[:id], :per_page => 10)
  end
  
  # Mapの編集画面を表示する
  def show
    # TODO: trek_map に保存されたものがあればそれを表示する！
    @g_map = GMap::WORLD
    
    @visits = @map.visits.paginate(:per_page => 10, :page => 1)  # 検索機能を追加したらここのバリエーションを増やす
  end
  
  def destroy
    @map.destroy
    flash[:notice] = "旅の地図「#{ERB::Util.h(@map.name)}」を削除しました。"
    redirect_to my_maps_path
  end
  
  def new
    @map = current_user.maps.build
  end
  
  def create
    @map = current_user.maps.create(params[:map])
    if @map.new_record?
      render :action => 'new'
    else
      flash[:notice] = "旅の地図「#{ERB::Util.h(@map.name)}」を作成しました。"
      redirect_to my_maps_path
    end
  end
  
  def edit
  end
  
  def update
    @map.attributes = params[:map]
    if @map.save
      flash[:notice] = "旅の地図「#{ERB::Util.h(@map.name)}」を変更しました。"
      redirect_to my_maps_path
    else
      render :action => 'edit'
    end
  end
  
  protected
  def default_url_options(options = nil)
    if options && @map
      case options[:controller]
        when 'my_visits'
          return {:map_id => @map.id}
        when 'maps'
          return {:url_name => current_user.url_name, :id => @map.id}
      end
    end
    if options && options[:controller] == 'my_visits' && @map
      return {:map_id => @map.id}
    end
    return {}
  end
  
  private
  def load_map
    @map = current_user.maps.find(params[:id])
  end

  class LinkRenderer < WillPaginate::LinkRenderer
    protected
    def page_link(page, text, attributes = {})
      @template.link_to_remote text, :update => 'visits_paging', :url => @template.instance_eval{my_visits_path(:page => page)}, :method => :get, :html => attributes
    end
  end
end
