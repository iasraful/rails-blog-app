Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :posts do
    resources :comments, only: [ :create, :destroy ]
  end

  root "posts#index"
end
