class Product < ApplicationRecord
  belongs_to :user
  has_many :user_journey_maps, dependent: :destroy
  has_one :session, as: :sessionable, dependent: :destroy

  accepts_nested_attributes_for :user_journey_maps
end
