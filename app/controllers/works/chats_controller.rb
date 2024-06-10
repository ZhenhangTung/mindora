# frozen_string_literal: true

class Works::ChatsController < ApplicationController
  include Works::ChatsHelper

  before_action :authenticate_user
  before_action :set_session, only: [:show, :create]

  def index
    @session = @current_user.session || @current_user.create_session
    redirect_to works_chat_path(@session)
  end

  def show
    @chat_histories = @session.chat_histories.order(:created_at)
  end

  def create
    if chat_params[:content].blank?
      render json: { status: 'error', message: 'Content cannot be blank' }, status: :unprocessable_entity
      return
    end

    @chat = @session.store_human_message(chat_params[:content])

    broadcast_human_content(@session.id, chat_params[:content])

    ChatsJob.perform_later(@current_user.id, @session.id, chat_params[:content])

    render json: { status: 'Message received', chat: @chat }, status: :ok
  end

  private

  def set_session
    if params[:session_id]
      @session = Session.find(params[:session_id])
    elsif params[:id]
      @session = Session.find(params[:id])
    end

    unless @session
      flash[:error] = "查找会话失败"
      redirect_to works_products_path
    end
  end

  def chat_params
    params.require(:message).permit(:content, :product_id)
  end
end
