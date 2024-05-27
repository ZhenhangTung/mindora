class UserJourneyMapConversationsJob < ApplicationJob
  queue_as :default

  def perform(user_journey_map_id)
    user_journey_map = UserJourneyMap.find_by(id: user_journey_map_id)

    return unless user_journey_map

    product = user_journey_map.product
    session = user_journey_map.session

    user = product.user

    recent_messages = session.chat_histories.order(created_at: :desc).limit(6).reverse

    latest_message = recent_messages.pop

    history_messages = recent_messages.map do |msg|
      role = msg.message.dig('data', 'type') == ChatHistory::MESSAGE_TYPES[:human] ? '用户' : '助手'
      "#{role}: #{msg.message_content}"
    end.join("\n")

    prompt_params = {
      description: product.description,
      target_user: product.target_user,
      history_messages: history_messages,
      current_message: latest_message&.message_content || ''
    }

    prompt = PromptManager.get_template_prompt(:user_journey_map, prompt_params)

    ai_response = ChatGptService.get_response(prompt, user.id, :default, 0.7)
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

    # TODO: stream response
    # complete_response = ""
    #
    # ChatGptService.stream_response(prompt, :default, 0.7) do |chunk|
    #   ai_response = chunk.dig("choices", 0, "delta", "content")
    #   next unless ai_response
    #
    #   complete_response += ai_response
    #
    #   response = {
    #     type: ChatHistory::MESSAGE_TYPES[:ai],
    #     content: ai_response,
    #     uuid: response_uuid
    #   }
    #
    #   ActionCable.server.broadcast(
    #     "user_journey_map_#{user_journey_map_id}",
    #     response
    #   )
    # end
    #
    # session.store_ai_message(complete_response)

  end

end
