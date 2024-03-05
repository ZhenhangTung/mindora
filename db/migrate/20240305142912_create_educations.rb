class CreateEducations < ActiveRecord::Migration[7.0]
  def change
    create_table :educations do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :school
      t.string :major
      t.date :start_date
      t.date :end_date
      t.string :degree

      t.timestamps
    end
  end
end
