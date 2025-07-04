Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  resource :session
  resources :passwords, param: :token
  resources :games do
    resources :areas
    resources :characters
    resource :play, only: [ :show ], controller: "games/play"
    resources :messages, only: [ :create ], controller: "games/messages"
    resources :dm_messages, only: [ :create ], controller: "games/dm_messages"
    resource :dm, only: [ :show ], controller: "games/dm"
    resource :configuration, only: [ :show ], controller: "games/configurations" do
      resources :messages, only: [ :create ], controller: "games/configurations/messages"
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "games#index"
end
