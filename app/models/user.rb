class User < ApplicationRecord
  has_secure_password
  has_one :resume # Assuming each user has one resume for now

end
