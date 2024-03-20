class AddProjectToWorkExperiences < ActiveRecord::Migration[7.0]
  def change
    add_column :work_experiences, :experience_type, :string
    add_column :work_experiences, :project_name, :string
  end
end
