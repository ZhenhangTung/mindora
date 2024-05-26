class Setting < ApplicationRecord
  belongs_to :user
  validates :nickname, length: { maximum: 50 }, allow_blank: true
end
