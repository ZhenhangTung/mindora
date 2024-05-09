class UserInterview < ApplicationRecord
  has_one_attached :audio

  validates :topic, presence: true, length: { maximum: 100 }
  validates :interviewee, presence: true, length: { maximum: 100 }
  validates :audio, content_type: ['audio/mp3', 'audio/mpeg', 'audio/wav'], size: { less_than: 10.megabytes }
  validates :transcript, presence: false
  validates :summary, presence: false

  # Callbacks (Example: To process the audio or transcript)
  # before_save :process_transcript, if: :transcript_changed?

  private

  def process_transcript
    # Placeholder method for processing the transcript
    # Add business logic here if needed
  end

end
