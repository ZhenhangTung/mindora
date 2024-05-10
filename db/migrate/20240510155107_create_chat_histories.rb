class CreateChatHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_histories do |t|
      t.jsonb :message
      t.references :session, index: true, null: false, foreign_key: true

      t.timestamps
    end
  end
end
