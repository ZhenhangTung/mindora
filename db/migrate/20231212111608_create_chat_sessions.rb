class CreateChatSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_sessions do |t|
      t.references :assistant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
