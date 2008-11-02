require 'test_helper'

class VisitsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:visits)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_visit
    assert_difference('Visit.count') do
      post :create, :visit => { }
    end

    assert_redirected_to visit_path(assigns(:visit))
  end

  def test_should_show_visit
    get :show, :id => visits(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => visits(:one).id
    assert_response :success
  end

  def test_should_update_visit
    put :update, :id => visits(:one).id, :visit => { }
    assert_redirected_to visit_path(assigns(:visit))
  end

  def test_should_destroy_visit
    assert_difference('Visit.count', -1) do
      delete :destroy, :id => visits(:one).id
    end

    assert_redirected_to visits_path
  end
end
