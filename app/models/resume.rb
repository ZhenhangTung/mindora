class Resume < ApplicationRecord

  has_one_attached :original_file
  has_one_attached :improved_file
end
