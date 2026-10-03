Rails.application.routes.draw do
  root "home#show"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  resources :groups, only: %i[ new create show edit update ] do
    member { post :regenerate_invite }
    resources :memberships, only: %i[ update destroy ]
    resource :prize, only: :update
  end

  get  "join/:code", to: "invitations#show", as: :invitation
  post "join/:code", to: "invitations#create"

  resources :results, only: %i[ index new create destroy ] do
    collection { post :manual }
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
