class Questionnaire < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy
  has_one :session, as: :sessionable, dependent: :destroy

  validates :title, :target_user, presence: true

  accepts_nested_attributes_for :questions, reject_if: :all_blank, allow_destroy: true
end
