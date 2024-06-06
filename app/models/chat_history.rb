class ChatHistory < ApplicationRecord
  belongs_to :session

  validates :message, presence: true
  validate :message_must_be_valid_json

  before_save :normalize_message

  MESSAGE_TYPES = {
    human: 'human',
    ai: 'ai'
  }.freeze

  # get message type
  def message_type
    message.dig('data', 'type') || message['type']
  end

  # get message content
  def message_content
    message.dig('data', 'content')
  end

  def rendered_message_content
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, extensions = { tables: true })
    markdown.render(message_content).html_safe
  end

  # Scope to filter messages by type
  scope :of_type, ->(type) { where("message ->> 'type' = ?", type) }
  scope :of_data_type, ->(data_type) { where("message -> 'data' ->> 'type' = ?", data_type) }

  def update_message_content(new_content)
    message_data = message.deep_dup
    message_data['data']['content'] = new_content
    update(message: message_data)
  end

  private
  def message_must_be_valid_json
    errors.add(:message, 'must be a valid JSON structure') unless message.is_a?(Hash) && message.key?('data')
  end

  def normalize_message
    self.message['data']['content'].strip! if message.dig('data', 'content').is_a?(String)
  end
end
