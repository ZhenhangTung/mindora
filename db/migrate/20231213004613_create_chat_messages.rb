class CreateChatMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.text :message_text
      t.string :sender_role

      t.timestamps
    end
  end
end
