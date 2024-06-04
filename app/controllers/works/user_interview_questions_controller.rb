class Works::UserInterviewQuestionsController < ApplicationController
  before_action :set_product, only: [:create]

  def new

  end

  def create
    prompt_params = {
      assumptions: params[:assumptions],
      target_user: @product.target_user,
      product_description: @product.description
    }

    prompt = PromptManager.get_template_prompt(:user_interview_questions, prompt_params)
    client = OpenAI::Client.new(
      request_timeout: 300,
      )
    response = client.chat(
      parameters: {
        temperature: 0.2,
        messages: [
          {
            "role": "system",
            "content": PromptManager.get_system_prompt(:default)
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content }
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
  end
end
