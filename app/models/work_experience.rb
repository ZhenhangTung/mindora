class WorkExperience < ApplicationRecord
  belongs_to :resume

  EXPERIENCE_TYPES = ['work', 'project'].freeze

  validates :experience_type, inclusion: { in: EXPERIENCE_TYPES }
  validates :project_name, :start_date, presence: true, if: -> { experience_type == 'project' }
  validates :company, :position, :start_date, presence: true, if: -> { experience_type == 'work' }

  def project?
    experience_type == 'project'
  end
end
