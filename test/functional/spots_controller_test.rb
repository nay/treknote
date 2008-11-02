require 'test_helper'

class SpotsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:spots)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_spot
    assert_difference('Spot.count') do
      post :create, :spot => { }
    end

    assert_redirected_to spot_path(assigns(:spot))
  end

  def test_should_show_spot
    get :show, :id => spots(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => spots(:one).id
    assert_response :success
  end

  def test_should_update_spot
    put :update, :id => spots(:one).id, :spot => { }
    assert_redirected_to spot_path(assigns(:spot))
  end

  def test_should_destroy_spot
    assert_difference('Spot.count', -1) do
      delete :destroy, :id => spots(:one).id
    end

    assert_redirected_to spots_path
  end
end
