class CreateResumes < ActiveRecord::Migration[7.0]
  def change
    create_table :resumes do |t|
      t.string :name
      t.string :gender
      t.string :phone_number
      t.string :email

      t.timestamps
    end
  end
end
