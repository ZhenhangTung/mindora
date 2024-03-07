class Resume < ApplicationRecord
  has_many :work_experiences, dependent: :destroy
  has_many :educations, dependent: :destroy

  has_one_attached :original_file
  has_one_attached :enhanced_resume


  validates :original_file, attached: true, content_type: ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            size: { less_than: 5.megabytes, message: 'is too large' }


  # Method to update resume with extracted data
  def update_with_extracted_data(data)
    self.transaction do
      self.name = data[:name] if data.key?(:name)
      self.gender = data[:gender] if data.key?(:gender)
      self.phone_number = data[:phone_number] if data.key?(:phone_number)
      self.email = data[:email] if data.key?(:email)

      # Assuming `data` is a hash with :work_experiences and :educations keys
      data[:work_experiences].each do |we_data|
        we_data = parse_date_fields(we_data)
        self.work_experiences.create!(we_data)
      end

      data[:educations].each do |ed_data|
        ed_data = parse_date_fields(ed_data)
        self.educations.create!(ed_data)
      end

      # Add any other fields in `data` that should update the resume itself
      # self.update!(other_fields: data[:other_fields])

      # Save changes or raise an exception if validations fail
      self.save!
    end
  end

  private

  def parse_date_fields(record)
    # Convert date fields from String to Date for both start_date and end_date
    record[:start_date] = Date.parse(record[:start_date]) if record[:start_date].present?
    record[:end_date] = Date.parse(record[:end_date]) if record[:end_date].present?
    record
  end
end
