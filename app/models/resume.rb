class Resume < ApplicationRecord
  belongs_to :user

  has_many :work_experiences, dependent: :destroy
  has_many :educations, dependent: :destroy

  accepts_nested_attributes_for :work_experiences, :educations, :allow_destroy => true

  has_one_attached :original_file
  # has_one_attached :enhanced_resume # TODO: Add this line to enable attaching enhanced resume

  validates :original_file, attached: true, on: :create


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
      work_experiences_attributes = data[:work_experiences].each do |we_data|
        parse_date_fields(we_data)
      end

      educations_attributes = data[:educations].each do |ed_data|
        parse_date_fields(ed_data)
      end

      self.work_experiences_attributes = work_experiences_attributes
      self.educations_attributes = educations_attributes

      # Add any other fields in `data` that should update the resume itself
      # self.update!(other_fields: data[:other_fields])

      # Save changes or raise an exception if validations fail
      self.save!
    end
  end

  # Checks if the resume owner is currently a student
  def is_student?
    educations.any? { |edu| edu.end_date.nil? || edu.end_date > Date.today }
  end

  def non_project_work_experiences
    work_experiences.where(experience_type: WorkExperience::EXPERIENCE_TYPES[0]).order(start_date: :desc)
  end

  def project_work_experiences
    work_experiences.where(experience_type: WorkExperience::EXPERIENCE_TYPES[1]).order(start_date: :desc)
  end

  private

  def parse_date_fields(record)
    # Convert start_date from String to Date if present and valid
    begin
      record[:start_date] = Date.parse(record[:start_date]) if record[:start_date].present? && valid_date_format?(record[:start_date])
    rescue ArgumentError
      # Log error, set to nil, or handle as needed
      record[:start_date] = nil
    end

    # Convert end_date from String to Date if present and valid
    begin
      record[:end_date] = Date.parse(record[:end_date]) if record[:end_date].present? && valid_date_format?(record[:end_date])
    rescue ArgumentError
      # Log error, set to nil, or handle as needed
      record[:end_date] = nil
    end

    record
  end

  # Helper method to check if a date string is in a valid format
  def valid_date_format?(date_str)
    # Define the desired format here; e.g., 'YYYY-MM-DD' or 'YYYY-MM'
    date_format = '%Y-%m-%d' # Example for 'YYYY-MM' format
    DateTime.strptime(date_str, date_format)
    true
  rescue ArgumentError
    false
  end
end
