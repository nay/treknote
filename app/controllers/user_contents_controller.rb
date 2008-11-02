class UserContentsController < ApplicationController
  before_filter :load_target_user
  
  private
  def load_target_user
    @target_user = User.find_by_url_name(params[:url_name])
    raise ActiveRecord::RecordNotFound unless @target_user
  end
  def load_map(key = :map_id)
    @map = @target_user.maps.find(params[key])
  end
  def load_visit(key = :visit_id)
    @visit = @target_user.visits.find(params[key])
  end
  
end