class ChatController < ApplicationController
  before_action :set_persistent_user_id

  def index
    # This action can be used to show the chat interface
  end

  def show
    @chat_history = ChatMessage.where(user_id: @user_id)

  end

  def set_persistent_user_id
    cookies.permanent[:anonymous_user_id] ||= SecureRandom.uuid
    @user_id = cookies[:anonymous_user_id]
  end
end
