Rails.application.routes.draw do
  get 'resumes/new'
  get 'resumes/create'
  get 'resumes/show'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'

  # Defines the root path route ("/")
  root "resumes#new"
  resources :chat, only: [:index, :create]

  namespace :api do
    post '/chatgpt/inspirations', to: 'chat_gpt#inspirations'
    get '/chatgpt/messages', to: 'chat_gpt#index'
    post '/chatgpt/messages', to: 'chat_gpt#create'
    post '/chatgpt/discussions', to: 'chat_gpt#discuss'
  end
end
