Carriage::Engine.routes.draw do
  root to: "dashboard#index"

  get "o/:token", to: "tracking#open", as: :open, format: "gif"
  get "c/:token", to: "tracking#click", as: :click
  get "u/:token", to: "unsubscribes#show", as: :unsubscribe

  resources :lists do
    resources :subscribers, only: [ :index, :new, :create, :destroy ]
    resource :csv_import, only: [ :new, :create ]
    get :export, on: :member
  end

  resources :segments

  resources :campaigns do
    member do
      get :preview
      post :send_test
      post :send_now
      post :schedule
      post :duplicate
    end
  end
end
