class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  stylesheet 'users'
  before_filter :login_required, :only => [:edit, :update]
  

  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      
#      self.current_user = @user
#      redirect_back_or_default(my_maps_path)
#      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "#{ERB::Util.h(current_user.login)}さん、ご登録ありがとうございます。ユーザー登録が完了しました。"
    end
    redirect_back_or_default('/')
  end
  
  def edit
    @user = current_user
    @title = "TrekNote - プロフィール情報の変更"
  end
  
  def update
    @user = User.find(current_user.id)
    @user.attributes = params[:user]
    unless params[:new_password].blank?
      @user.password = params[:new_password]
      @user.password_confirmation = params[:new_password_confirmation]
    end
    if @user.save
      current_user.reload
      redirect_to my_maps_path
    else
      render :action => 'edit'
    end
  end
  
  
  protected
  

end
