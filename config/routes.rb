ActionController::Routing::Routes.draw do |map|

  map.resources :maps, :path_prefix => '/:url_name' do
    map.resources :visits, :controller => 'visits', :name_prefix => nil, :path_prefix => '/:url_name/maps/:map_id', :collection => {:spots => :get} do
      map.resources :notes, :controller => 'notes', :name_prefix => nil, :path_prefix => '/:url_name/maps/:map_id/visits/:visit_id'
      map.resources :photos, :controller => 'photos', :name_prefix => nil, :path_prefix => '/:url_name/maps/:map_id/visits/:visit_id'
    end
  end
  
  map.visits_in_year '/:url_name/maps/:map_id/visits/in/:year', :controller => 'visits', :requirements => {:year => /[0-9]*/}
  
  map.resources :my_maps do
    map.resources :visits,
      :controller => 'my_visits', :name_prefix => 'my_', :path_prefix => '/my_maps/:map_id',
      :member => {:edit_photos => :get, :edit_notes => :get, :edit_photos_from_flickr => :get, :edit_photos_from_file => :get, :remember_edit_photos_status => :put} do 
        map.resources :photos,
          :controller => 'my_photos', :name_prefix => 'my_', :path_prefix => '/my_maps/:map_id/visits/:visit_id'
        map.resources :notes,
          :controller => 'my_notes', :name_prefix => 'my_', :path_prefix => '/my_maps/:map_id/visits/:visit_id'
      end
  end

  map.resources :users

  map.resource :session
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'

  map.resources :spots, :collection => {:save_new_map_in_session => :put}


  map.logout '/logout', :controller => 'sessions', :action => 'destroy'  

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
