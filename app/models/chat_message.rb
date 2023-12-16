class ChatMessage < ApplicationRecord
  SENDER_ROLE_USER = 'user'.freeze
  SENDER_ROLE_ASSISTANT = 'assistant'.freeze


  belongs_to :chat_session

  # Define roles
  enum sender_role: { user: SENDER_ROLE_USER, assistant: SENDER_ROLE_ASSISTANT }

  # Validations
  validates :message_text, presence: true
  validates :sender_role, presence: true, inclusion: { in: sender_roles.keys }
end
