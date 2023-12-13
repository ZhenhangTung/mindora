class ChatController < ApplicationController
  before_action :set_persistent_user_id

  def index
    # Prepare a new chat message instance for the form
    @chat_message = ChatMessage.new
  end

  def show
    @chat_history = ChatMessage.where(anonymous_user_id: @anonymous_user_id)
  end

  def create
    @chat_session = ChatSession.find_or_initialize_by(anonymous_user_id: cookies[:anonymous_user_id])

    if @chat_session.new_record? && !@chat_session.save
      # Handle the case where the chat session cannot be saved
      # This could be due to validation errors or other issues
      # You should respond appropriately, maybe rendering an error message
      p 'failed to save chat session'
      return
    end

    # Build the chat message associated with the chat session
    @chat_message = @chat_session.chat_messages.build(chat_message_params)

    if @chat_message.save
      p 'successfully saved message'
      # turbo_stream.prepend 'messages', partial: 'chat/message', locals: { message: @chat_message }
    else
      p 'failed to save message'
      # render turbo_stream: turbo_stream.replace('new_message', partial: 'chat/form', locals: { message: @chat_message })
    end
  end

  private
  def set_persistent_user_id
    cookies.permanent[:anonymous_user_id] ||= SecureRandom.uuid
    @anonymous_user_id = cookies[:anonymous_user_id]
  end

  def process_with_ai_assistant(message)
    # Placeholder for AI assistant logic
    "Response from AI assistant for message: #{message}"
  end

  def chat_message_params
    params.require(:chat_message).permit(:message_text, :sender_role).merge(sender_role: 'user')
  end
end
