class UserJourneyMap < ApplicationRecord
  # Direct association with Product
  belongs_to :product

  # Polymorphic association with PromptForm
  has_many :prompt_forms, as: :formable, dependent: :destroy

  has_one :session, as: :sessionable, dependent: :destroy
end
