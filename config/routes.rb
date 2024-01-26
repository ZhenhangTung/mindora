Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'

  # Defines the root path route ("/")
  root "chat#index"
  resources :chat, only: [:index, :create]

  namespace :api do
    post '/chatgpt/inspirations', to: 'chat_gpt#inspirations'
    post '/chatgpt/messages', to: 'chat_gpt#messages'
  end
end
