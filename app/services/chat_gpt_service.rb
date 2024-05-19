# frozen_string_literal: true

class ChatGptService
  def self.get_response(user_prompt, system_prompt_name = :default, temperature = 0.7, uri_base = nil, history_messages = [])
    client = if uri_base
               OpenAI::Client.new(
                 request_timeout: 600,
                 uri_base: uri_base
               )
             else
               OpenAI::Client.new(
                 request_timeout: 600
               )
             end

    system_prompt = PromptManager.get_system_prompt(system_prompt_name)

    # 构建消息列表
    messages = [
      {
        "role": "system",
        "content": system_prompt
      }
    ]
    # 添加历史消息
    messages.concat(history_messages)
    # 添加当前用户消息
    messages << {
      "role": "user",
      "content": user_prompt
    }

    response = client.chat(
      parameters: {
        temperature: temperature,
        messages: messages
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  def self.stream_response(user_prompt, system_prompt_name = :default, temperature = 0.7, uri_base = nil, &block)
    client = if uri_base
               OpenAI::Client.new(
                 request_timeout: 600,
                 uri_base: uri_base
               )
             else
               OpenAI::Client.new(
                 request_timeout: 600
               )
             end

    system_prompt = PromptManager.get_system_prompt(system_prompt_name)
    client.chat(
      parameters: {
        temperature: temperature,
        messages: [
          {
            "role": "system",
            "content": system_prompt
          },
          {
            "role": "user",
            "content": user_prompt
          }
        ],
        stream: proc { |chunk, _bytesize| yield chunk if block_given? }
      }
    )
  end
end
