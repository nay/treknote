class MyPhotosController < ApplicationController
  before_filter :login_required
  before_filter :load_map, :load_visit
  before_filter :load_photo, :only => [:show, :destroy]
  
  def index
    page = params[:include] ? @visit.photos.page_including(params[:include]) : params[:page]
    render :partial => 'list', :locals => {:photos => @visit.photos.paginate(:page => page, :per_page => 6)}
  end
  
  def show
    send_stored_file(@photo)
  end

  def create
    photo = nil
    begin
      if params[:photo].kind_of?(Hash) && params[:photo][:flickr_photo_id]
        photo = FlickrPhoto.new(params[:photo])
      else 
        photo = FilePhoto.new(:buffer => params[:photo])
      end
      @visit.photos << photo
    rescue => e
      logger.error("Could not create photo.")
      logger.error(e)
      p e
      p e.backtrace
      error_message = "このファイルはアップロードできません。"
    end
    if !photo || photo.new_record?
      logger.info(photo.errors.inspect)
      error_message ||= photo.errors.full_messages.join("<br />")
      responds_to_parent do
        render :update do |page|
          page.alert(error_message)
        end
      end
    else
      proc = lambda {
        render :update do |page|
          page << remote_function(:update => 'photos', :url => my_photos_path(:include => photo.id), :method => :get)
        end
      }
      photo.kind_of?(FlickrPhoto) ? proc.call : responds_to_parent(&proc)
    end
  end

  def destroy
    prev = @photo.lower_item;
    @photo.destroy
    flash[:notice] = "写真を削除しました。"
    redirect_to edit_photos_my_visit_path(prev ? {:include => prev.id} : {})
  end
  
  protected
  def default_url_options(options = nil)
    if options && @map && @visit
      case options[:controller]
        when 'my_photos'
          return {:map_id => @map.id, :visit_id => @visit.id}
        when 'my_visits'
          return {:map_id => @map.id, :id => @visit.id}
      end
    end
    return {}
  end
  
  
  private
  def load_map
    @map = current_user.maps.find(params[:map_id])
  end

  def load_visit
    @visit = @map.visits.find(params[:visit_id])
  end

  def load_photo
    @photo = @visit.photos.find(params[:id])
  end

  class LinkRenderer < WillPaginate::LinkRenderer
    protected
    def page_link(page, text, attributes = {})
      @template.link_to_remote text, :update => 'photos', :url => @template.instance_eval{my_photos_path(:page => page)}, :method => :get, :html => attributes
    end
  end

end
