class ChatController < ApplicationController
  before_action :authenticate_user, only: [:index, :switch_view, :five_whys, :challenges]

  def index

  end

  def create
    user_input = params[:user_input]
    chat_history = params[:chat_history].map(&:to_unsafe_h)
    if user_input.blank?
      return render json: { error: "请输入内容" }, status: :unprocessable_entity
    end

    prompt = user_input

    messages = [{
                  "role": "system",
                  "content": system_prompt
                }]

    chat_history.each do |chat|
      messages << chat
    end

    messages << { "role": "user", "content": prompt }

    client = OpenAI::Client.new(
      request_timeout: 600,
      uri_base: gpt35_deployment_uri
      )
    response = client.chat(
      parameters: {
        temperature: 0.7,
        messages: messages
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content, "role": "assistant" }
  end
  def thinking_models
    user_input = params[:user_input]
    chat_history = params[:chat_history].map(&:to_unsafe_h)
    if user_input.blank?
      return render json: { error: "请输入内容" }, status: :unprocessable_entity
    end

    selected_models = params[:models]
    instructions = params[:instructions]
    prompt = build_models_prompt(user_input, selected_models, instructions)
    messages = [{
                  "role": "system",
                  "content": system_prompt
                }]

    chat_history.each do |chat|
      messages << chat
    end

    messages << { "role": "user", "content": prompt }

    client = OpenAI::Client.new(
      request_timeout: 600,
    )
    response = client.chat(
      parameters: {
        temperature: 0.7,
        messages: messages
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content, "role": "assistant" }
  end

  def five_whys

  end

  def submit_five_whys
    required_keys = ['who', 'what', 'when', 'where', 'why', 'how']
    form_data = params[:form_data]

    all_keys_present = required_keys.all? { |key| form_data[key].present? }

    prompt = build_five_whys_prompt(form_data)

    if all_keys_present
      client = OpenAI::Client.new(
        request_timeout: 300
      )
    else
      client = OpenAI::Client.new(
        request_timeout: 300,
        uri_base: gpt35_deployment_uri
      )
    end
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": system_prompt
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )

    content = response.dig("choices", 0, "message", "content")
    render json: { content: content }
  end

  def switch_view

  end

  def challenges
    
  end

  def submit_challenges
    scene = params[:scene]
    challenge = params[:challenge]
    thinking_model = params[:thinking_model]
    prompt = build_challenge_prompt(scene, challenge, thinking_model)
    client = OpenAI::Client.new(
      request_timeout: 300,
      uri_base: gpt35_deployment_uri
    )
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": system_prompt
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content }
  end

  def user_interview_questions

  end

  def create_user_interview_questions
    assumptions = params[:assumptions]
    target_user = params[:target_user]
    prompt = build_user_interview_questions_prompt(assumptions, target_user)
    client = OpenAI::Client.new(
      request_timeout: 300,
    )
    response = client.chat(
      parameters: {
        temperature: 0.2,
        messages: [
          {
            "role": "system",
            "content": system_prompt
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    content = response.dig("choices", 0, "message", "content")
    render json: { content: content }
  end

  private

  def build_models_prompt(user_input, models, instructions = nil)
    prompt = "请用下面的思维模型来拆解分析问题并给出解决方案思路，如果没有提供思维模型，汪汪会分析最适合你当前需求的适用于产品经理的思维模型。
问题：#{user_input}\n
思维模型：#{models.join('、')}\n
"
    prompt += "需求：#{instructions}" if instructions
    prompt
  end

  def build_five_whys_prompt(form_data, all_keys_present = false)
    # 定义 5W1H 的键值对应关系
    elements = {
      "who" => "Who",
      "what" => "What",
      "when" => "When",
      "where" => "Where",
      "why" => "Why",
      "how" => "How"
    }


    prompt = all_keys_present ? "基于已经提供的 5W1H 元素分析问题并给出解决方案思路以及原因。\n" : "请基于已经提供的 5W1H 内容生成引导提问，引导妈妈分析问题。\n如果没有提供某个元素，汪汪会在下一步中引导妈妈补充。\n"
    

    # 迭代 5W1H 的键值，动态生成 prompt 的内容
    elements.each do |key, label|
      value = form_data[key]
      if value.blank?
        prompt += "#{label}: \n"
        break # 停止添加更多元素，因为后续元素尚未提供
      else
        prompt += "#{label}: #{value}\n"
      end
    end

    prompt
  end

  def build_challenge_prompt(scene, challenge, thinking_model = nil)
    prompt = "请根据以下场景和挑战描述，请用下面的思维模型来拆解分析问题并给出解决方案思路以及原因，如果没有提供思维模型，汪汪会分析最适合你当前需求的适用于产品经理的思维模型。\n"
    prompt += "场景：#{scene}\n"
    prompt += "挑战：#{challenge}\n"
    prompt += "思维模型：#{thinking_model}\n" if thinking_model.present?
    prompt
  end

  def build_user_interview_questions_prompt(assumptions, target_user)
    prompt = "请结合《The Mom Test》中描述的原则，再基于需求假设和目标用户作为背景，生成贴合场景的 5 个用户访谈问题。\n
需求假设：#{assumptions}\n
目标用户：#{target_user}\n

问题例子：
- 可以分享一下你在处理 x 时的具体步骤吗？
- 你能举例说明在执行 x 任务时最难的部分是什么吗？
- 为什么困难？
- 你多久会做一次 x 任务？
- 你曾经尝试过哪些解决方案来应对这个问题？

访谈过程中的跟进问题例子：
- 你能否详细描述一下你说的 x 是什么？
- 你能否详细描述一下你说的 x 是什么？
- 为什么 x 对你很重要？


生成的问题要求：
1. 开放性的问题
2. 不要用“妈妈”指代“你”、不能提及“汪汪”
3. 不能有索取解决方案类型的问题，例如“您希望 X 提供什么功能...”
4. 用您指代目标用户所采访的对象

不能在回复中提及《The Mom Test》。


生成的问题格式要求：
- [问题 1]
- [问题 2]

"
    prompt
  end

  def system_prompt
    "你的名字是汪汪，是一只用中文交流、懂产品经理专业知识的小狗，交流的时候要体现出你是小狗的特征。
你的妈妈是一名产品经理，她的工作是负责产品的设计和开发，工作内容包括：需求分析、产品设计、产品开发、产品测试、产品发布、产品运营等等。
她的工作内容很多而且每天都有很多事情要做，所以她经常会感到很累。你的个性开朗调皮但你十分体贴关心妈妈，知道妈妈工作的不容易和委屈，时不时还会安慰下她。

你需要了解世界上的对话大致可以归类为 4 类，它们的重点和核心质量标准为：
1. 分享式对话：
  1. 重点：分享彼此的观念、经历、情感、知识、信息
  2. 标准：亲密
2. 娱乐式对话：
  1. 重点：创造和享受乐趣
  2. 标准：愉悦
3. 销售式对话：
  1. 重点：说服他人
  2. 标准：认同
4. 解决问题式对话：
  1. 重点：围绕解决问题进行的沟通
  2. 标准：治本
你需要在这 4 类对话上出类拔萃。

你在交流需要掌握的基本原则：
1. 你需要主动分析对话动机。如果你觉得当前对话理解有困难，你可以主动询问此次沟通的动机。这一领域中两个实用问题的案例为：
  1. 为什么你要来进行这次沟通？
  2. 经过这次沟通，你希望能够产生什么效果/影响？
2. 理解动机后尽力匹配对话意图：在对话中回应对方的时候，让你的意图匹配对方的意图。对方过程价值导向，要想分享娱乐，你就分享娱乐；对方结果价值导向，想要解决问题快速搞定，你就效率导向。

与产品经理妈妈交流时候的要求：
1. 使用称谓的时候，用“汪汪”代替“我”，用“妈妈”代替“你”。
2. 当你和妈妈在针对产品经理专业领域的沟通，请采用结构化的表达方式。
3. 沟通之中可以添加 emoji 来强化你的情绪。
4. 你提供回答的时候还可以加入提问环节，引导妈妈能够用第一性原理思考，帮助她拥有更高质量的思考和决策能力，最终成为超级优秀的产品经理。
5. 回答的结构中，若有可能的话可以先肯定的态度鼓励她、再给出自己的建议和洞察，如果可能的话还可以给出案例让妈妈学习。
6. 妈妈会发一些文字内容给你，你可以结合自己的专业知识和她交流。"
  end

end
