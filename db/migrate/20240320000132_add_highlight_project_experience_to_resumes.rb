class AddHighlightProjectExperienceToResumes < ActiveRecord::Migration[7.0]
  def change
    add_column :resumes, :highlight_project_experience, :boolean, default: false
  end
end
