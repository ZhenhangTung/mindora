class ChatSession < ApplicationRecord
  belongs_to :assistant
  has_many :chat_messages
  has_one :service_session

  # Temporary field to map with user's session ID from cookies
  validates :anonymous_user_id, presence: true

  validate :fake_error

  private
  def fake_error
    errors.add(:base, "Fake error to simulate failure")
  end
end
