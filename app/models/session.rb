class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true

  has_many :chat_histories, dependent: :destroy

  # 专门存储 AI 消息的方法
  def store_ai_message(content)
    store_message(ChatHistory::MESSAGE_TYPES[:ai], content)
  end

  # 专门存储人类消息的方法
  def store_human_message(content)
    store_message(ChatHistory::MESSAGE_TYPES[:human], content)
  end

  private

  # 通用方法用于存储不同类型的消息
  def store_message(type, content)
    chat_histories.create(
      message: {
        data: {
          type: type,
          content: content
        },
        type: type
      }
    )
  end
end
