class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Use the provided user_id from the subscription request
    user_id = params[:user_id]
    stream_from "chat_channel_#{user_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
