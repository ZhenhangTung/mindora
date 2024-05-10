class PromptForm < ApplicationRecord
  belongs_to :formable, polymorphic: true
end
