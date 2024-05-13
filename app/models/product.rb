class Product < ApplicationRecord
  has_many :user_journey_maps, dependent: :destroy

  accepts_nested_attributes_for :user_journey_maps
end
