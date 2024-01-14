Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "chat#index"
  resources :chat, only: [:index, :create]

  namespace :api do
    post '/chatgpt/discussions', to: 'chat_gpt#discuss'
  end
end
