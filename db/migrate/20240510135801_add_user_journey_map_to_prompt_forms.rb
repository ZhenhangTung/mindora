class AddUserJourneyMapToPromptForms < ActiveRecord::Migration[7.0]
  def change
    add_reference :prompt_forms, :user_journey_map, polymorphic: true, null: false
  end
end
