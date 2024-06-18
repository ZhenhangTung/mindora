# frozen_string_literal: true

class ChatsJob < ApplicationJob
  include GptHelper

  queue_as :default

  def perform(user_id, session_id, prompt)
    return unless prompt
    session = Session.find(session_id)
    return unless session
    user = User.find(user_id)
    return unless user

    recent_messages = session.chat_histories.order(created_at: :desc).limit(6).reverse

    message_history = recent_messages.map do |msg|
      role = case msg.message_type
             when ChatHistory::MESSAGE_TYPES[:human]
               'user'
             when ChatHistory::MESSAGE_TYPES[:ai]
               'assistant'
             end
      processed_message = msg.message_content.gsub(/妈妈|豆子/, '你')
      { role: role, content: processed_message }
    end

    response_uuid = SecureRandom.uuid
    complete_response = ""

    ChatGptService.stream_response(prompt, user_id, :default, 0.7, nil, message_history) do |chunk|
      ai_response = chunk.dig("choices", 0, "delta", "content")
      next unless ai_response

      complete_response += ai_response

      response = {
        type: ChatHistory::MESSAGE_TYPES[:ai],
        content: ai_response,
        uuid: response_uuid,
      }

      ActionCable.server.broadcast(
        "session_#{session.id}",
        response
      )

      sleep(0.1) # 100ms延迟，避免并发问题
    end

    session.store_ai_message(complete_response)
  end
end
