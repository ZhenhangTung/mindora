# frozen_string_literal: true

class ResumeStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "resume_status_channel_#{params[:resume_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
