# frozen_string_literal: true

class ChatGptService
  def self.get_response(user_prompt, system_prompt_name = :default, temperature = 0.7, uri_base = nil)
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
    response = client.chat(
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
      }
    )
    response.dig("choices", 0, "message", "content")
  end
end
