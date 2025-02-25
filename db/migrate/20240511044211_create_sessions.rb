class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :sessionable, polymorphic: true, index: true, null: false

      t.timestamps
    end
  end
end
