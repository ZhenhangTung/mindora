class Api::ChatGptController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    user_identifier = fetch_user_identifier
    return if performed?

    chat_session = ChatSession.find_by(anonymous_user_id: user_identifier)
    if chat_session
      render json: chat_session.chat_messages.order(created_at: :asc)
    else
      render json: []
    end
  end
  def create
    @assistant = fetch_assistant
    return if performed?

    user_identifier = fetch_user_identifier
    return if performed?

    message_text = params[:message_text]
    unless message_text.present?
      return render json: { error: "Message parameter is missing" }, status: :bad_request
    end

    @chat_session = find_or_create_chat_session(user_identifier)
    return if performed?

    openai_response_message = create_chat_message(message_text)
    return if performed? || openai_response_message.nil?

    resp = { message_text: openai_response_message.message_text, sender_role: openai_response_message.sender_role }
    ActionCable.server.broadcast("chat_channel_#{user_identifier}", {response: resp})
    render json: { response: resp }
  end

  # TODO: implement me
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
    # FIXME: hardcoded channel id
    ActionCable.server.broadcast("chat_channel_4cfdfd1e-d3b2-48b4-8668-410393fa35cd", {response: resp})
    render json: { response: resp }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # Backward compatible API
  def discuss
    unless params[:message].present?
      return render json: { error: "Message parameter is missing" }, status: :bad_request
    end

    client = OpenAI::Client.new

    message = params[:message]

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
    render json: { response: resp }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private
  def fetch_assistant
    assistant = Assistant.find_by_name('产品汪汪')
    render json: { error: "Assistant not found" }, status: :not_found unless assistant.present?
    assistant
  end

  def fetch_user_identifier
    user_identifier = request.headers['X-User-Identifier']
    render json: { error: "User identifier header is missing" }, status: :bad_request unless user_identifier.present?
    user_identifier
  end

  def find_or_create_chat_session(user_identifier)
    chat_session = ChatSession.find_or_initialize_by(anonymous_user_id: user_identifier, assistant_id: @assistant.id)
    begin
      chat_session.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to save chat session: #{e.message}")
      render json: { error: "Failed to save chat session: #{e.message}" }, status: :internal_server_error
    end
    chat_session
  end

  def create_chat_message(message_text)
    chat_message = @chat_session.chat_messages.build(message_text: message_text, sender_role: ChatMessage::SENDER_ROLE_USER)
    begin
      chat_message.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to save chat message: #{e.message}")
      render json: { error: "Failed to save message: #{e.message}" }, status: :internal_server_error
    end
    # Get OpenAI's response
    openai_response = handle_openai_interaction

    # Check if response is obtained and save it
    if openai_response
      assistant_message = @chat_session.chat_messages.create(
        message_text: openai_response,
        sender_role: ChatMessage::SENDER_ROLE_ASSISTANT
      )
      return assistant_message
    else
      render json: { error: "Failed to obtain response from OpenAI" }, status: :internal_server_error
      return nil
    end
  end

  def handle_openai_interaction
    system_message = { role: "system", content: @assistant.instructions }
    recent_chat_history = @chat_session.chat_messages.order(created_at: :desc).limit(6).reverse.map do |message|
      { role: message.sender_role, content: message.message_text }
    end
    messages_for_api = [system_message] + recent_chat_history

    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        # model: @assistant.model,
        model: 'gpt-3.5-turbo', # TODO: fixme
        messages: messages_for_api,
        temperature: 0.7,
      })

    response.dig("choices", 0, "message", "content")
  end
end
