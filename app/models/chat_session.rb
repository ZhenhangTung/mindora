class ChatSession < ApplicationRecord
  belongs_to :assistant

  # Temporary field to map with user's session ID from cookies
  validates :anonymous_user_id, presence: true
end
