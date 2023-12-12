class Assistant < ApplicationRecord
  # Validations can be added here, for example:
  validates :external_id, :name, :model, presence: true
  validates :external_id, uniqueness: true


end
