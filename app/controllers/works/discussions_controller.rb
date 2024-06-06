class Works::DiscussionsController < ApplicationController
  before_action :authenticate_user, only: [:index]
  before_action :set_product, only: [:create]
  def index
  end

  def create
    user_input = params[:user_input]
    chat_history = params[:chat_history].map(&:to_unsafe_h)
    if user_input.blank?
      return render json: { error: "请输入内容" }, status: :unprocessable_entity
    end

    selected_models = params[:models]

    prompt_params = {
      target_user: @product.target_user,
      product_description: @product.description,
      topic: user_input,
      thinking_models: selected_models.join('、')
    }

    prompt = PromptManager.get_template_prompt(:thinking_models, prompt_params)

    messages = [{
                  "role": "system",
                  "content": PromptManager.get_system_prompt(:default)
                }]

    chat_history.each do |chat|
      messages << chat
    end

    messages << { "role": "user", "content": prompt }

    client = OpenAI::Client.new(
      request_timeout: 600,
      uri_base: gpt35_deployment_uri
    )
    response = client.chat(
      parameters: {
        temperature: 0.7,
        messages: messages
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content, "role": "assistant" }
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
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
