class CreateUserInterviews < ActiveRecord::Migration[7.0]
  def change
    create_table :user_interviews do |t|
      t.string :topic
      t.string :interviewee
      t.text :transcript
      t.text :summary

      t.timestamps
    end
  end
end
