class CreateAssistants < ActiveRecord::Migration[7.0]
  def change
    create_table :assistants do |t|
      t.string :external_id
      t.string :name
      t.text :description
      t.string :model
      t.text :instructions

      t.timestamps
    end
  end
end
