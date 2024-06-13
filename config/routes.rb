require 'sidekiq/web'

Rails.application.routes.draw do
  # Defines the root path route ("/")
  root 'homepage#index'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'

  # Defines the routes for the users controller
  resources :users, only: [:create]
  get 'signup', to: 'users#new', as: 'signup'
  get 'reset_password', to: 'users#reset_password_form'
  post 'reset_password', to: 'users#reset_password'

  # resources :sessions, only: [:new, :create, :destroy]
  # Defines the routes for the sessions controller
  get 'sessions/new'
  get 'login', to: 'sessions#new', as: 'new_session'
  post 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'

  resources :resumes, except: [:edit]
  get 'resumes/:id/customize', to: 'resumes#customize', as: 'customize_resume'
  post 'resumes/work_experiences/optimize', to: 'resumes#optimize'
  post 'resumes/:id/job_match', to: 'resumes#job_match'

  get 'interviews/new', to: 'interviews#new', as: 'new_interviews'
  post 'interviews/self_introduction', to: 'interviews#self_introduction', as: 'self_introduction'
  post 'interviews/potential_interview_questions', to: 'interviews#potential_interview_questions'
  post 'interviews/analyze_interview_questions', to: 'interviews#analyze_interview_questions'

  namespace :works do
    resources :questionnaires, only: [:index, :new, :create, :edit, :update] do
      post :chat, on: :member
    end
    resources :products, only: [:index, :new, :create, :edit, :update] do
      resources :user_journey_maps, except: [:edit, :update, :destroy] do
        member do
          post :create_prompt_form
        end
      end
      resources :user_interview_questions, only: [:new, :create]
      resources :discussions, only: [:index, :show] do
        post :chat, on: :member
      end
    end
    resources :sessions, only: [] do
      resources :chats, only: [:create]
    end
    resources :chats, only: [:index, :show]
  end

  resource :settings, only: [:create, :edit, :update]

  namespace :api do
    post '/chatgpt/inspirations', to: 'chat_gpt#inspirations'
    get '/chatgpt/messages', to: 'chat_gpt#index'
    post '/chatgpt/messages', to: 'chat_gpt#create'
    post '/chatgpt/discussions', to: 'chat_gpt#discuss'
  end

  namespace :admin do
    get 'reports/weekly_growth', to: 'reports#weekly_growth', as: :weekly_growth_report
    mount Sidekiq::Web => "/sidekiq"
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
