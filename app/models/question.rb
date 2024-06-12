class Question < ApplicationRecord
  belongs_to :questionnaire

  validates :content, presence: true
end
