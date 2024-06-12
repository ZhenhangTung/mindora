class Questionnaire < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy

  validates :title, :target_user, presence: true
end
