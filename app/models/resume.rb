class Resume < ApplicationRecord

  has_one_attached :original_file
  has_one_attached :enhanced_resume


  validates :original_file, attached: true, content_type: ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            size: { less_than: 5.megabytes, message: 'is too large' }
end
