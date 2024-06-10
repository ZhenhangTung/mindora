class Works::DiscussionsController < ApplicationController
  include Works::ChatsHelper

  before_action :authenticate_user, only: [:index, :show]
  before_action :set_product, only: [:index, :show, :chat]
  before_action :set_session, only: [:show, :chat]
  def index
    @session = @product.session || @product.create_session
    redirect_to works_product_discussion_path(@product, @session)
  end

  def chat
    if chat_params[:content].blank?
      render json: { status: 'error', message: 'Content cannot be blank' }, status: :unprocessable_entity
      return
    end

    @chat = @session.store_human_message(chat_params[:content])

    broadcast_human_content(@session.id, chat_params[:content])

    prompt_params = {
      target_user: @product.target_user,
      product_description: @product.description,
      topic: chat_params[:content],
      thinking_models: []
    }

    prompt = PromptManager.get_template_prompt(:thinking_models, prompt_params)

    ChatsJob.perform_later(@current_user.id, @session.id, prompt)

    render json: { status: 'Message received', chat: @chat }, status: :ok
  end

  def show
    @chat_histories = @session.chat_histories
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
  end

  def set_session
    @session = Session.find(params[:id])

    unless @session
      flash[:error] = "查找会话失败"
      redirect_to works_products_path
    end
  end

  def chat_params
    params.require(:message).permit(:content)
  end

  def build_models_prompt(user_input, models, instructions = nil)
    prompt = "请用下面的思维模型来拆解分析问题并给出解决方案思路，如果没有提供思维模型，汪汪会分析最适合你当前需求的适用于产品经理的思维模型。
问题：#{user_input}\n
思维模型：#{models.join('、')}\n
    "
    prompt += "需求：#{instructions}" if instructions
    prompt
  end
end
