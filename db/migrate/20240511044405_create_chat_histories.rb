class CreateChatHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_histories do |t|
      t.jsonb :message
      t.references :session, null: false, foreign_key: true, type: :uuid

      # t.timestamps
      # compatible with python langchain's design
      t.datetime :created_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.index :message, using: :gin
    end
  end
end
