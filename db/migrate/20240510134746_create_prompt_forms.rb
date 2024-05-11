class CreatePromptForms < ActiveRecord::Migration[7.0]
  def change
    create_table :prompt_forms do |t|
      t.json :content
      t.references :formable, polymorphic: true, null: false, index: true

      t.timestamps
    end
  end
end
