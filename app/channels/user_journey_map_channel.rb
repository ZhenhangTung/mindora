# frozen_string_literal: true

class UserJourneyMapChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_journey_map_#{params[:user_journey_map_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
