class ServiceSession < ApplicationRecord
  belongs_to :chat_session

  # Attributes for identifying and interacting with the external service
  validates :external_id, presence: true  # The ID or reference used by the external service

end
