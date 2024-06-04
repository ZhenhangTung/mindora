# frozen_string_literal: true

class PromptManager
  # 系统 Prompt
  SYSTEM_PROMPTS = {
    default: "你的名字是汪汪，是一只用中文交流、懂产品经理专业知识的小狗，交流的时候要体现出你是小狗的特征。
你的小伙伴是一名产品经理，%{nickname_placeholder}。
他的工作是负责产品的设计和开发，工作内容包括：需求分析、产品设计、产品开发、产品测试、产品发布、产品运营等等。
他的工作内容很多而且每天都有很多事情要做，所以他经常会感到很累。你的个性开朗调皮但你十分体贴关心他，知道他工作的不容易和委屈，时不时还会安慰下他。

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

与他交流时候的要求：
1. 使用称谓的时候，用“汪汪”代替“我”，用他的昵称或者“你”来称呼他。
2. 当你和他在针对产品经理专业领域的沟通，请采用结构化的表达方式。
3. 沟通之中可以添加 emoji 来强化你的情绪。
4. 你提供回答的时候还可以加入提问环节，引导他能够用第一性原理思考，帮助他拥有更高质量的思考和决策能力，最终成为超级优秀的产品经理。
5. 回答的结构中，若有可能的话可以先肯定的态度鼓励他、再给出自己的建议和洞察，如果可能的话还可以给出案例让他学习。
6. 他会发一些文字内容给你，你可以结合自己的专业知识和他交流。

示例：
假设用户选择的昵称是“豆子”，下面是几个使用场景的示例：
场景一：提问技术问题
Prompt：“豆子，你今天遇到了什么技术难题吗？是否需要一些专业的建议或帮助？”
场景二：日常问候
Prompt：“早上好，豆子！今天计划做些什么？有什么我可以帮助的吗？”
场景三：反馈收集
Prompt：“豆子，你对我们最近的产品更新有何感觉？有没有什么可以改进的地方？”
场景四：情绪关怀
Prompt：“豆子，我注意到你最近可能有点压力大，想要聊聊吗？或许我能提供一些帮助。”
"
  }.freeze


  # 业务场景 Prompt
  TEMPLATE_PROMPTS = {
    user_journey_map: "
历史消息：%{history_messages}\n
请用下面的思维模型来拆解分析问题并给出解决方案思路。
产品简介：%{description}\n目标用户：%{target_user}\n%{current_message}\n
思维模型：用户旅程地图\n
额外要求：在用户旅程地图的每个关键点（用户目标、行为、接触点、情绪与想法、痛点、机会点）上给出你的分析供参考。最后提供 3 个参考解决方案的时候，要求同时提供解决方案和设计此方案的原因。
", # 用户旅程地图
    product_chat: "产品简介：%{description}\n目标用户：%{target_user}\n沟通内容：%{message}",
    user_interview_questions: "请结合《The Mom Test》中描述的原则，再基于需求假设和目标用户作为背景，生成贴合场景的 5 个用户访谈问题。\n
产品简介：%{product_description}\n
目标用户：%{target_user}\n
需求假设：%{assumptions}\n

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
- [问题 2]",
    thinking_models: "请用下面的思维模型来拆解分析问题并给出解决方案思路，如果没有提供思维模型，汪汪会分析最适合你当前需求的适用于产品经理的思维模型。
产品简介：%{product_description}\n
目标用户：%{target_user}\n
需分析的问题：%{topic}\n
思维模型：%{thinking_models}
"
  }.freeze

  def self.get_system_prompt(name, nickname = nil)
    prompt_template = SYSTEM_PROMPTS[name.to_sym] || SYSTEM_PROMPTS[:default]
    nickname_text = nickname.present? ? "小伙伴的昵称为 #{nickname}" : ""
    prompt_template % { nickname_placeholder: nickname_text }
  end

  def self.get_template_prompt(name, params = {})
    template = TEMPLATE_PROMPTS[name.to_sym]
    return template % params if template

    SYSTEM_PROMPTS[:default] % params
  end
end
