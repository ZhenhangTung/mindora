module Works::ChatsHelper
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
