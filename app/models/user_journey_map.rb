class UserJourneyMap < ApplicationRecord
  # Direct association with Product
  belongs_to :product

  # Polymorphic association with PromptForm
  has_many :prompt_forms, as: :formable
end
