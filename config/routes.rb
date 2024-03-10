Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'

  # Defines the root path route ("/")
  root "resumes#new"
  resources :resumes, only: [:new, :create, :show, :update]
  get 'resumes/:id/customize', to: 'resumes#customize'
  post 'resumes/work_experiences/optimize', to: 'resumes#optimize'
  post 'resumes/:id/job_match', to: 'resumes#job_match'

  resources :chat, only: [:index, :create]

  namespace :api do
    post '/chatgpt/inspirations', to: 'chat_gpt#inspirations'
    get '/chatgpt/messages', to: 'chat_gpt#index'
    post '/chatgpt/messages', to: 'chat_gpt#create'
    post '/chatgpt/discussions', to: 'chat_gpt#discuss'
  end
end
