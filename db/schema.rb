# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_12_13_004613) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assistants", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.text "description"
    t.string "model"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.text "message_text"
    t.string "sender_role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "assistant_id", null: false
    t.string "anonymous_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_chat_sessions_on_assistant_id"
  end

  create_table "userconversations", primary_key: "messageid", id: { type: :serial, comment: "MessageID 是每条消息的唯一标识符，为自增主键。" }, comment: "UserConversations 表用于存储用户间的对话记录。", force: :cascade do |t|
    t.string "userid", limit: 255, null: false, comment: "UserID 代表发送消息的用户的唯一标识，通常是用户名或用户ID。"
    t.text "messagecontent", null: false, comment: "MessageContent 包含用户发送的实际消息文本。"
    t.datetime "timestamp", precision: nil, null: false, comment: "Timestamp 记录消息发送的具体时间。"
    t.jsonb "additionalinfo", comment: "AdditionalInfo 以 JSONB 格式存储与消息相关的附加信息，如设备类型、位置信息等。"
  end

  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "assistants"
end
