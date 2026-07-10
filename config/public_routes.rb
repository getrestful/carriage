Carriage::Public::Engine.routes.draw do
  get "o/:token", to: "tracking#open", as: :open, format: "gif"
  get "c/:token", to: "tracking#click", as: :click
  get "u/:token", to: "unsubscribes#show", as: :unsubscribe

  get  "lists/:list_id/signup", to: "signups#new", as: :list_signup
  post "lists/:list_id/signup", to: "signups#create"
  get  "confirm/:token", to: "confirmations#show", as: :confirm_subscription
end
