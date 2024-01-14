class Api::ChatGptController < ApplicationController
  skip_before_action :verify_authenticity_token

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
end
