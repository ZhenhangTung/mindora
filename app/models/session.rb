class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true

  has_many :chat_histories, dependent: :destroy
end
