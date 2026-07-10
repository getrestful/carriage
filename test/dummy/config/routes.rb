Rails.application.routes.draw do
  root to: "home#index"

  mount Carriage::Engine => "/carriage"
  mount Carriage::Public::Engine => "/c"
end
