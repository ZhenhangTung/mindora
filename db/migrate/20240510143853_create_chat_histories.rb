class CreateChatHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_histories do |t|
      t.string :session_id
      t.jsonb :message

      t.timestamps
    end
  end
end
