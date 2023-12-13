class ChatMessage < ApplicationRecord
  belongs_to :chat_session

  # Define roles
  enum sender_role: { user: 'user', assistant: 'assistant' }

  # Validations
  validates :message_text, presence: true
  validates :sender_role, presence: true, inclusion: { in: sender_roles.keys }
end
