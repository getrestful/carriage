Carriage::Engine.routes.draw do
  root to: "dashboard#index"

  resources :lists do
    resources :subscribers, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resource :csv_import, only: [ :new, :create ]
    get :export, on: :member
  end

  resources :segments

  resources :campaigns do
    member do
      match :preview, via: [ :get, :post ]
      get :preview_page
      post :send_test
      post :send_now
      post :schedule
      post :duplicate
    end
  end
end
