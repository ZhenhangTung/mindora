# frozen_string_literal: true

class Works::ChatsController < ApplicationController
  before_action :set_session

  def create
    if chat_params[:content].blank?
      render json: { status: 'error', message: 'Content cannot be blank' }, status: :unprocessable_entity
      return
    end

    @chat = @session.store_human_message(chat_params[:content])

    broadcast_human_content(@session.id, chat_params[:content])

    ChatsJob.perform_later(@session.id, chat_params[:product_id], chat_params[:content])

    render json: { status: 'Message received', chat: @chat }, status: :ok
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end

  def chat_params
    params.require(:message).permit(:content, :product_id)
  end

  def broadcast_human_content(session_id, content)
    response_uuid = SecureRandom.uuid
    response = {
      type: ChatHistory::MESSAGE_TYPES[:human],
      content: content,
      uuid: response_uuid
    }

    ActionCable.server.broadcast(
      "session_#{session_id}",
      response
    )
  end
end
