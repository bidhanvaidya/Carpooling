Ozride::Application.routes.draw do
  get "info/jobs"
  get "info/faq"

  get "info/privacy"

  get "info/terms"

  get "info/contact"

  get "info/about"

resources :users do  
resources :profiles do
  collection do
        get 'send_message'
        get 'reply_message'
        get 'trash'
        get 'accept'
        get 'reject'
        get 'accept_and_close' 
        post 'review_create'       
      end
end
end
  resources :posts do
      collection do
        get 'myposts'
        
      end
      member do
      	get 'make_booking'
      end
  end
match '/googleab837e83b3783fb6.html', 
      :to => proc { |env| [200, {}, ["google-site-verification: googleab837e83b3783fb6.html"]] }
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
	resources :homes
	match "/auth/:facebook/callback" => "sessions#create"
	match "/signout" => "sessions#destroy", :as => :signout
	
  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
   root :to => 'homes#index'
default_url_options :host => "ozide.com.au"
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
