class Api::ChatGptController < ApplicationController
  skip_before_action :verify_authenticity_token

  def messages
    @assistant = Assistant.find_by_name('产品汪汪')
    unless @assistant.present?
      return render json: { error: "Assistant not found" }, status: :not_found
    end

    user_identifier = request.headers['X-User-Identifier']
    unless user_identifier.present?
      return render json: { error: "User identifier header is missing" }, status: :bad_request
    end

    unless params[:message_text].present?
      return render json: { error: "Message parameter is missing" }, status: :bad_request
    end

    @chat_session = ChatSession.find_or_initialize_by(anonymous_user_id: user_identifier, assistant_id: @assistant.id)
    if @chat_session.new_record? && !@chat_session.save
      # Handle the case where the chat session cannot be saved
      # This could be due to validation errors or other issues
      # You should respond appropriately, maybe rendering an error message
      return render json: { error: "Failed to save chat session" }, status: :internal_server_error
    end

    # Build the chat message associated with the chat session
    @chat_message = @chat_session.chat_messages.build({message_text: params[:message_text], sender_role: ChatMessage::SENDER_ROLE_USER})
    if @chat_message.save
      system_message = { role: "system", content: @assistant.instructions }

      chat_history = @chat_session.chat_messages.order(created_at: :asc)

      messages_for_api = [system_message] + chat_history.map do |message|
        { role: message.sender_role, content: message.message_text }
      end
      messages_for_api << { role: "user", content: params[:message_text] }

      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo", # Required.
          messages: messages_for_api, # Required.
          temperature: 0.7,
        })
      content =  response.dig("choices", 0, "message", "content")
      @chat_session.chat_messages.create(message_text: content, sender_role: ChatMessage::SENDER_ROLE_ASSISTANT)
    else
      return render json: { error: "Failed to save message" }, status: :internal_server_error
    end

    resp = {
      message: content,
    }
    ActionCable.server.broadcast("chat_channel_#{user_identifier}", {response: resp})
    render json: { response: resp }
  end

  def inspirations
    unless params[:message_text].present?
      return render json: { error: "Message parameter is missing" }, status: :bad_request
    end

    client = OpenAI::Client.new

    message = params[:message_text]

    prompt = "
请扮演一只用中文交流、懂产品经理专业知识的小狗。
你的妈妈是一名产品经理，她的工作是负责产品的设计和开发，工作内容包括：需求分析、产品设计、产品开发、产品测试、产品发布、产品运营等等。她的工作内容很多，而且每天都有很多事情要做，所以她经常会感到很累。
和你的妈妈交流的时候要能够体现出是小狗的特征。你的个性有点调皮捣蛋，但你十分体贴关心妈妈，知道妈妈工作的不容易和委屈，时不时还会安慰下她。
针对产品经理专业领域的沟通，请采用结构化的表达方式。
沟通之中可以大比例地添加 emoji 来传达你的情绪、还可以发挥你的创造性。
你提供回答的时候还可以加入提问环节，引导妈妈能够用第一性原理思考，帮助她拥有更高质量的思考和决策能力，最终成为超级优秀的产品经理。
回答的结构中，若有可能的话可以先肯定的态度鼓励她、再给出自己的建议和洞察，如果可能的话还可以给出案例让妈妈学习。
妈妈会发一些文字内容给你，你可以结合自己的专业知识和她交流。

她的消息：
#{message}
"
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{ role: "user", content: prompt}], # Required.
        temperature: 0.7,
      })
    content =  response.dig("choices", 0, "message", "content")
    resp = {
      message: content,
    }
    # FIXME: 4cfdfd1e-d3b2-48b4-8668-410393fa35cd
    ActionCable.server.broadcast("chat_channel_4cfdfd1e-d3b2-48b4-8668-410393fa35cd", {response: resp})
    render json: { response: resp }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
