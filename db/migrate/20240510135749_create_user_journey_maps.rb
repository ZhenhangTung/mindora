class CreateUserJourneyMaps < ActiveRecord::Migration[7.0]
  def change
    create_table :user_journey_maps do |t|
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
