class Question < ApplicationRecord
  belongs_to :questionnaire

  validates :content, presence: true
  validates :type, presence: true, inclusion: { in: ->(_) { Question.descendants.map(&:to_s) } }
end
