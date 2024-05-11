class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.references :sessionable, polymorphic: true, null: false, index: true

      t.timestamps
    end
  end
end
