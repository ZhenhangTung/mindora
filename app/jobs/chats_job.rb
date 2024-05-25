# frozen_string_literal: true

class ChatsJob < ApplicationJob
  include GptHelper

  queue_as :default

  def perform(session_id, product_id, content)
    return unless content
    session = Session.find(session_id)
    return unless session
    product = Product.find(product_id)
    return unless product

    recent_messages = session.chat_histories.order(created_at: :desc).limit(6).reverse

    message_history = recent_messages.map do |msg|
      role = case msg.message_type
             when ChatHistory::MESSAGE_TYPES[:human]
               'user'
             when ChatHistory::MESSAGE_TYPES[:ai]
               'assistant'
             end
      { role: role, content: msg.message_content }
    end

    prompt_params = {
      description: product.description,
      target_user: product.target_user,
      message: content
    }

    prompt = PromptManager.get_template_prompt(:product_chat, prompt_params)

    ai_response = ChatGptService.get_response(prompt, :default, 0.7, nil, message_history)
    session.store_ai_message(ai_response)
    response_uuid = SecureRandom.uuid
    response = {
      type: ChatHistory::MESSAGE_TYPES[:ai],
      content: ai_response,
      uuid: response_uuid
    }

    ActionCable.server.broadcast(
      "session_#{session.id}",
      response
    )
  end
end
