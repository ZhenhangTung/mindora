class CreateServiceSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :service_sessions do |t|
      t.string :external_id
      t.json :metadata
      t.references :chat_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
