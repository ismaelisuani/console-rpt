Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :profile, only: %i[show update]

  root "dispatch#show"
  get "dispatch" => "dispatch#show", as: :dispatch

  # Dispatch actions on a radio
  resources :radios, only: [] do
    scope module: :radios do
      resources :links, only: %i[create destroy], param: :node
      resource :call, only: :create
      resource :ptt, only: :create
    end
  end

  resources :recordings, only: :index do
    resource :audio, only: :show, module: :recordings
  end

  namespace :units do
    resource :import, only: %i[new create]
  end
  resources :units, except: :show

  namespace :admin do
    resources :servers, except: :show do
      scope module: :servers do
        resource :connection_check, only: :create
      end
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
