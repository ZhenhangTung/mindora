class CreateQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :questionnaires do |t|
      t.string :title
      t.string :target_user
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
