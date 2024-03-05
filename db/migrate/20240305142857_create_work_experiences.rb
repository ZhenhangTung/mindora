class CreateWorkExperiences < ActiveRecord::Migration[7.0]
  def change
    create_table :work_experiences do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :position
      t.string :company
      t.date :start_date
      t.date :end_date
      t.text :project_experience

      t.timestamps
    end
  end
end
