class UserJourneyMap < ApplicationRecord
  # Direct association with Product
  belongs_to :product

  # Polymorphic association with PromptForm
  has_many :prompt_forms, as: :formable, dependent: :destroy, class_name: 'PromptForm::PromptForm'
  accepts_nested_attributes_for :product
  accepts_nested_attributes_for :prompt_forms

  has_one :session, as: :sessionable, dependent: :destroy
end
