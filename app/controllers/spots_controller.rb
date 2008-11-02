class SpotsController < ApplicationController

  # PUT /spots/save_new_map_in_session
  def save_new_map_in_session
    session[:new_map_center_lat] = params[:lat]
    session[:new_map_center_lng] = params[:lng]
    session[:new_map_zoom] = params[:zoom]
    render :nothing => true
  end
  
  # GET /spots
  # GET /spots.xml
  def index
    if params[:keyword]
      @spots = Spot.find(:all, :conditions => ["name like ?", "%#{params[:keyword]}%"])
    else
      @spots = Spot.find(:all)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @spots }
      format.json { render :json => @spots.to_json(:only => [:name, :latitude, :longitude, :visits_count])}
    end
  end

  # GET /spots/1
  # GET /spots/1.xml
  def show
    @spot = Spot.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @spot }
    end
  end

  # GET /spots/new
  # GET /spots/new.xml
  def new
    @title = "場所の登録"
    @spot = Spot.new
    

    @lat = session[:new_map_center_lat] || 34
    @lng = session[:new_map_center_lng] || 150
    @zoom = session[:new_map_zoom] || 1

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @spot }
    end
  end

  # GET /spots/1/edit
  def edit
    @spot = Spot.find(params[:id])
  end

  # POST /spots
  # POST /spots.xml
  def create
    @spot = Spot.new(params[:spot])

    respond_to do |format|
      if @spot.save
        flash[:notice] = 'Spot was successfully created.'
        format.html { redirect_to(@spot) }
        format.xml  { render :xml => @spot, :status => :created, :location => @spot }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @spot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spots/1
  # PUT /spots/1.xml
  def update
    @spot = Spot.find(params[:id])

    respond_to do |format|
      if @spot.update_attributes(params[:spot])
        flash[:notice] = 'Spot was successfully updated.'
        format.html { redirect_to(@spot) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @spot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spots/1
  # DELETE /spots/1.xml
  def destroy
    @spot = Spot.find(params[:id])
    @spot.destroy

    respond_to do |format|
      format.html { redirect_to(spots_url) }
      format.xml  { head :ok }
    end
  end
end
