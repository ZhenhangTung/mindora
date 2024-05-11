class Product < ApplicationRecord
  has_many :user_journey_maps, dependent: :destroy
end
