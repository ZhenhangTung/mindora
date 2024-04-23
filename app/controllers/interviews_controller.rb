class InterviewsController < ApplicationController
  include ResumesHelper

  before_action :authenticate_user, :set_resume, only: [:new]
  before_action :get_resume_from_form, only: [:self_introduction, :potential_interview_questions, :analyze_interview_questions]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def new

  end

  def create
  end

  def self_introduction
    prompt = build_self_introduction_prompt(@resume, @resume_text)

    client = OpenAI::Client.new(
      request_timeout: 300,
      )
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "请根据简历信息、公司介绍（如有）与职位描述（如有），撰写一份 1 分钟的适合中等语速表达的产品经理职位面试场景下的自我介绍。要求在引用经历的时候能引用这段经历下客观的量化数据。
可以借鉴好故事的结构和对应的在面试开场 1 分钟自我介绍的重心：
1. 强有力的开端：可以通过提出一个引人入思的问题来制造悬疑、分享一个令人惊讶的事实或简短描述一个挑战作为故事的开端。
2. 鲜明的角色：需要清晰地展现自己的角色特质，比如作为一个问题解决者、创新者或团队合作者。通过具体的例子展示这些特质，可以让听众更好地了解你是谁。
3. 紧张的冲突：可以摘选简历中的一段经历，突出你如何面对并克服职业生涯中的挑战或问题，不仅展示了你的解决问题能力，还能引发听众的情感共鸣。
4. 清晰的结构：开端（介绍自己），发展（描述挑战和你的行动），高潮（解决问题的成果），结尾（你对未来的展望和希望能够为公司做出贡献）。
5. 情感共鸣：真实地表达你对工作的热爱和你希望达成的目标，可以加深面试官对你的印象。
6. 有力的结尾：你可以以一个对话邀请结束，比如提出一个问题或表示你期待有机会进一步展现你的能力。

另外还可以在内容中语气声调、情感等提示性信息，以及在内容中加入一些自然的停顿，辅助应聘者在面试场景中更好的表达自己。

请按照以下格式生成自我介绍：
[语气声调、情感等提示性信息]
[自我介绍内容段落]

"
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )

    self_introduction = response.dig("choices", 0, "message", "content")
    render json: { self_introduction: self_introduction }

  end

  def potential_interview_questions
    prompt = build_potential_interview_questions(@resume, @resume_text)
    pp prompt

    client = OpenAI::Client.new(
      request_timeout: 300,
      )
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "请扮演产品经理的面试官，根据公司介绍（如有）、职位介绍（如有）、简历内容生成 10 个可能会面试候选人的问题，同时附上面试此问题的动机、考察点和回答思路。
请按照以下格式提供回答：
• 问题：[面试问题]
  • 动机：[问题背后的动机]
  • 考察点：[问题考察的技能或素质]
  • 回答思路：[回答思路]
"
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )

    interview_questions = response.dig("choices", 0, "message", "content")
    render json: { interview_questions: interview_questions }
  end

  def analyze_interview_questions
    prompt = build_analyze_interview_questions(@resume, @resume_text)

    client = OpenAI::Client.new(
      request_timeout: 300,
      )
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "请扮演资深产品经理面试官，结合用户的简历内容和面试问题，从面试官角度分析每个问题背后的动机、考察点以及回答思路。
请按照以下格式提供回答：
• 问题：[面试问题]
  • 动机：[问题背后的动机]
  • 考察点：[问题考察的技能或素质]
  • 回答思路：[回答思路]

• 问题：[面试问题]
  • 动机：[问题背后的动机]
  • 考察点：[问题考察的技能或素质]
  • 回答思路：[回答思路]
"
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    analysis = response.dig("choices", 0, "message", "content")
    render json: { analysis: analysis }
  end


  def set_resume
    if current_user
      @resume = current_user.resumes.find(params[:resume_id]) if params[:resume_id]
    else
      flash[:warning] = "请先登录"
      redirect_to login_path
    end
  end

  private

  def build_self_introduction_prompt(resume, resume_text)
    if resume
      prompt = "
简历内容：
基本信息：
姓名：#{resume.name}
性别：#{resume.gender}
教育背景：#{resume.educations.map { |edu| "#{edu.school} - #{edu.major}" }.join("\n")}

项目经验：
#{resume.work_experiences.map(&:project_experience).join("\n")}

#{params[:company_description] ? "公司介绍：#{params[:company_description]}" : ""}
#{params[:job_description] ? "职位介绍：#{params[:job_description]}" : ""}
    "
    elsif resume_text
      prompt = "
简历内容（未格式化）：
#{resume_text}
公司介绍：#{params[:company_description]}
职位介绍：#{params[:job_description]}
"
    else
      raise "resume is required"
    end
    prompt
  end

  def build_potential_interview_questions(resume, resume_text)
    if resume
      prompt = "
简历内容：
基本信息：
姓名：#{resume.name}
性别：#{resume.gender}
教育背景：#{resume.educations.map { |edu| "#{edu.school} - #{edu.major}" }.join("\n")}

项目经验：
#{resume.work_experiences.map(&:project_experience).join("\n")}

    #{params[:company_description] ? "公司介绍：#{params[:company_description]}" : ""}
    #{params[:job_description] ? "职位介绍：#{params[:job_description]}" : ""}
"
    elsif resume_text
      prompt = "
简历内容（未格式化）：
#{resume_text}
公司介绍：#{params[:company_description]}
职位介绍：#{params[:job_description]}
"
    else
      raise "resume is required"
    end
    prompt
  end

  def build_analyze_interview_questions(resume, resume_text)
    interview_questions = params[:interview_questions]
    if resume
      prompt = "
简历内容：
#{resume.work_experiences.map(&:project_experience).join("\n")}

面试问题：
#{interview_questions}
    "
    elsif resume_text
      prompt = "
简历内容（未格式化）：
#{resume_text}

面试问题：
#{interview_questions}
    "
    else
      raise "resume is required"
    end
    prompt
  end

  def get_resume_from_form
    @resume_text = read_pdf_content(params[:resume_file]) if params[:resume_file]
    @resume = Resume.find(params[:resume_id]) if params[:resume_id]
  end

end
