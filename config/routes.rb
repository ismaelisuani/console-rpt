Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :profile, only: %i[show update]

  root "dispatch#show"
  get "dispatch" => "dispatch#show", as: :dispatch

  # Dispatch actions on a radio
  resources :radios, only: [] do
    member do
      post :link
      post :unlink
    end
  end

  resources :units, except: :show do
    collection do
      get :import, action: :new_import
      post :import
    end
  end

  namespace :admin do
    resources :servers, except: :show do
      member { post :check }
    end
    resources :radios, except: :show
    resources :radio_groups, except: :show
    resources :users, except: :show
    resources :roles, except: :show
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
