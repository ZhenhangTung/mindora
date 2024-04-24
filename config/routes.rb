Rails.application.routes.draw do
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

  # Defines the root path route ("/")
  root "resumes#new"
  resources :resumes, only: [:index, :new, :create, :show, :update]
  get 'resumes/:id/customize', to: 'resumes#customize'
  post 'resumes/work_experiences/optimize', to: 'resumes#optimize'
  post 'resumes/:id/job_match', to: 'resumes#job_match'
  get 'resumes/:id/prepare_interviews', to: 'resumes#prepare_interviews'
  post 'resumes/:id/potential_interview_questions', to: 'resumes#potential_interview_questions'
  post 'resumes/:id/self_introduction', to: 'resumes#self_introduction'
  post 'resumes/:id/project_experience_stories', to: 'resumes#project_experience_stories'
  post 'resumes/:id/analyze_interview_questions', to: 'resumes#analyze_interview_questions'

  resources :chat, only: [:index, :create]
  get 'chat/thinking_models/five_whys', to: 'chat#five_whys', as: 'five_whys'
  post 'chat/thinking_models/five_whys', to: 'chat#submit_five_whys'
  get 'chat/thinking_models/switch_view', to: 'chat#switch_view', as: 'switch_view'
  post 'chat/thinking_models', to: 'chat#thinking_models'
  get 'chat/challenges', to: 'chat#challenges', as: 'challenges'
  post 'chat/challenges', to: 'chat#submit_challenges'

  namespace :api do
    post '/chatgpt/inspirations', to: 'chat_gpt#inspirations'
    get '/chatgpt/messages', to: 'chat_gpt#index'
    post '/chatgpt/messages', to: 'chat_gpt#create'
    post '/chatgpt/discussions', to: 'chat_gpt#discuss'
  end
end
