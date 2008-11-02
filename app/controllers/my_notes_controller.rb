class MyNotesController < ApplicationController
  before_filter :login_required
  before_filter :load_map, :load_visit
  before_filter :load_note, :only => [:edit, :update, :destroy]

  def edit
    # 二箇所を書き換える
    render :update do |page|
      page.replace_html 'noteForm', :partial => 'form'
      page.replace_html 'notes', :partial => 'list', :locals => {:notes => @visit.notes.paginate(:page => 1, :per_page => 10), :target_note => @note } # とりあえず。ほんとは同じページにするとかの工夫必要
    end
  end

  def new
    @note = @visit.notes.build
    render :partial => 'form'
  end

  def create
    @visit.notes.create!(params[:note])
    flash[:notice] = "ノートを作成しました。"
    redirect_to edit_notes_my_visit_path(:id => @visit.id, :map_id => @map.id)
  end
  
  def update
    @note.attributes = params[:note]
    @note.save!
    flash[:notice] = "ノートを変更しました。"
    redirect_to edit_notes_my_visit_path(:id => @visit.id, :map_id => @map.id)
  end

  def destroy
    @note.destroy
    flash[:notice] = "ノート「#{ERB::Util.h(@note.subject_or_head)}」を削除しました。"
    redirect_to edit_notes_my_visit_path
  end

  private
  def load_map
    @map = current_user.maps.find(params[:map_id])
  end

  def load_visit
    @visit = @map.visits.find(params[:visit_id])
  end

  def load_note
    @note = @visit.notes.find(params[:id])
  end

end
