class ResumesController < ApplicationController
  include ResumesHelper

  before_action :set_resume, only: [:show, :update, :customize, :prepare_interviews]
  before_action :authenticate_user, only: [:index, :new, :show, :customize]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @resumes = current_user.resumes
  end
  def new
    @current_step = 'new_resume'
    @resume = Resume.new
  end

  def create
    @resume = current_user.resumes.build(resume_params)

    if @resume.original_file.attached?
      # TODO: Any space for improvement?
      begin
        # Save the resume record first
        @resume.save!

        # Enqueue the processing job
        ProcessResumeJob.perform_later(@resume.id)

        flash[:success] = '简历上传成功！正在后台处理，稍后可查看解析结果。'
        redirect_to @resume
      rescue => e
        # Log error with detailed information
        Rails.logger.error "Resume upload failed for user #{current_user.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        flash[:error] = "简历上传失败！错误信息: #{e.message}"
        redirect_to new_resume_path
      end
    else
      # Log the absence of an attached file
      Rails.logger.warn "Resume upload attempt without an attached file by user #{current_user.id}"
      flash[:error] = '未找到上传的文件，请重试。'
      redirect_to new_resume_path
    end
  end

  def update
    Rails.logger.debug { "Before update: #{params.inspect}" }
    modified_params = adjust_date_params(resume_params)
    if @resume.update(modified_params)
      Rails.logger.debug { "After update: #{@resume.work_experiences.inspect}" }
      flash[:success] = '简历更新成功！'
      redirect_to @resume
    else
      # Log error messages if update fails
      Rails.logger.error { "Update failed for Resume ID: #{@resume.id}. Errors: #{@resume.errors.full_messages.join(", ")}" }
      flash[:error] = '简历更新失败，请重新尝试。'
      redirect_to @resume
    end
  end

  def show
    @current_step = 'show_resume'
  end

  def customize
    @current_step = 'customize_resume'
    render 'show'
  end

  def optimize
    # Check for required parameters
    if params[:project_experience].present? && params[:experience_type].present? && WorkExperience::EXPERIENCE_TYPES.include?(params[:experience_type])
      original_text = params[:project_experience]
      experience_type = params[:experience_type]

      optimized_text = if experience_type == WorkExperience::EXPERIENCE_TYPES[0]
                         optimize_work_exp_with_chatgpt(original_text)
                       else
                         optimize_project_exp_with_chatgpt(original_text)
                       end

      render json: { optimized_text: optimized_text }
    else
      # Respond with an error message if required params are missing or invalid
      render json: { error: "Missing or invalid parameters" }, status: :bad_request
    end
  end

  def optimize_work_exp_with_chatgpt(original_text)
    prompt = "工作经历的原始内容：#{original_text}"
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        temperature: 0.2,
        # max_tokens: 200,
        # top_p: 0.9,
        messages: [
          {
            "role": "system",
            "content": "请将下述工作经历合并并精简至70字内，同时突出职责、贡献和成就，参考如下格式：
• 职责: [简要描述您的主要职责，如领导产品开发团队。]
• 贡献: [描述您为公司创造的具体价值，如增加20%的用户增长。]
• 成就: [列出您的个人成就，如获得年度最佳员工奖。]

请确保描述中明确突出量化数据；对于原内容中没有可量化数据的部分，请插入占位符 '[请提供数据]'，以便简历撰写者填入自己的数据。"
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  def optimize_project_exp_with_chatgpt(original_text)
    # TODO: replace the following prompt
    prompt = "以下是针对产品经理简历中项目经历的修改：
修改前：
原有系统X业务分散、数据不互通、协同困难，需建立全新的Y系统，涉及数个外部系统的整合重构，需满足多个部门的个性化需求：
1、完善工具A、工具B、工具C等低代码工具，从0到1设计Y系统产品方案，实现全流程低代码开发，节省一定比例的开发工作量；
2、搭建事项接入平台，完善通用能力，最小化开发业务个性化需求，制定系统的平台接入规范，实现超过一定数量的事项快速接入；对接数个外部系统，实现数据互联互通；
3、项目收入达到一定金额，完全替代原有业务系统。

修改后：
• 成果：在Z地区搭建首个特定功能的平台Q，解决了相关公司之间的不互通问题、办理流程繁琐、多人协作困难等问题。为A数量的企业提供服务，业务覆盖B地区，项目收入达到C金额。
• 挑战：由于功能P的办理流程繁琐，以及相关公司之间的不互通问题，导致企业办理相关业务时效率低下，协作困难。
• 任务：设计一个能够简化办理流程、实现相关公司间功能P的互通，并支持高效协作的管理平台Q。
• 行动：从0到1实现功能P的办理、使用、管理全流程的产品功能，提供公有SaaS服务或私有化部署产品能力，并根据高频业务场景提供特定功能的通用能力，以满足多个业务系统的快速对接需求。

修改前：
#{original_text}

修改后：
"
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        temperature: 0.2,
        # max_tokens: 200,
        # top_p: 0.9,
        messages: [
          {
            "role": "system",
            "content": '请根据下面的示例，采用STAR结构（情境、任务、行动、结果）重新撰写你的工作经历。确保描述中明确突出量化数据；对于原内容中没有可量化数据的部分，请插入占位符 "[请提供数据]"，以便简历撰写者填入自己的数据。特别是在工作成果部分，要求放在首位并清晰地展示成果的影响力和量化成绩。

案例修改指导：

1. 成果：描述你的主要成就，包括具体的影响力、收益或改进情况。确保包含量化的结果，如提升的百分比、收入增长额、服务的企业数量等。如果没有具体数字，请使用占位符要求补充。
   例：• 成果：成功实施了X项目，为公司带来了[请补充具体金额]的收入增长，提升了[请补充具体百分比]%的运营效率。
2. 挑战：简要描述你面对的工作背景或挑战，包括涉及的行业、目标用户、关键问题等。如可能，提供具体数据支持背景描述。
   例：• 挑战：在X行业，由于Y问题，导致公司效率低下，每年损失达到[请补充具体数字]。
3. 任务：明确你需要解决的具体任务或目标，尽量量化任务的目标或预期成果。
   例：• 任务：重新设计Z流程，目标是减少至少[请补充目标比例]%的处理时间，并提高客户满意度至[请补充具体目标值]。
4. 行动：详细说明为达成任务采取的具体行动。包括实施的策略、采用的技术、团队协作方式等，和量化的目标或成果相结合。
   例：• 行动：领导了一个由[请补充团队人数]人组成的团队，采用[请补充方法或技术]，在[请补充时间周期]内完成了项目，超过了设定目标的[请补充具体百分比]%。
'
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  def job_match
    resume = Resume.find(params[:id])
    job_description = params[:job_description]
    job_match = match_job_with_resume(job_description, resume)
    render json: { job_match: job_match }
  end

  def match_job_with_resume(job_description, resume)
    prompt = "
JD 内容：
#{job_description}
简历内容：
#{resume.work_experiences.map(&:project_experience).join("\n")}

职位匹配：
"
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "请从提供的工作经历中提取与职位要求关键元素和权重最匹配的信息，形成 3 项简洁的匹配项。专注于展示关键成就、技能和客观数据，确保每项描述都是简洁且有力的。每项匹配不超过 40 字，避免使用原始经历中的小标题如‘成果:’、‘挑战:’、‘任务:’和‘行动:’等。如果某项要求没有直接匹配的经历，请使用占位符“[请提供相关经验或技能]”提示用户补充。

请按照以下格式提供匹配结果：
• [匹配的关键词]： [相关的工作经历部分/数据支持/成就。如果无匹配，使用占位符。]
• [匹配的关键词]： [相关的工作经历部分/数据支持/成就。如果无匹配，使用占位符。]

示例：
• 数据分析：在XX项目中分析了超过10万条用户数据，通过对数据的深入分析，最终产品用户满意度提升了20%。
• 效率提升：负责领导XY项目团队，短期内提高了项目交付速度30%，并减少了15%的超时交付。
• 产品优化：为YZ产品设计了一个新功能，成功吸引了[请补充具体用户增长数量]新用户。

"
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  private

  def set_resume
    if current_user
      @resume = current_user.resumes.find(params[:id])
    else
      flash[:warning] = "请先登录"
      redirect_to login_path
    end
  end

  def resume_params
    params.require(:resume).permit(
      :original_file,
      :name,
      :email,
      :phone_number,
      :gender,
      :highlight_project_experience,
      work_experiences_attributes: [
        :id,
        :company,
        :position,
        :start_date,
        :end_date,
        :project_experience,
        :experience_type,
        :project_name,
        :_destroy
      ],
      educations_attributes: [
        :id,
        :school,
        :major,
        :start_date,
        :end_date,
        :_destroy
      ]
    )
  end

  def adjust_date_params(params)
    # Regular expression to match YYYY-MM format
    date_format_regex = /\A\d{4}-\d{2}\z/

    params.tap do |whitelisted|
      if whitelisted[:work_experiences_attributes]
        whitelisted[:work_experiences_attributes].each do |_key, experience|
          experience[:start_date] = "#{experience[:start_date]}-01" if experience[:start_date].present? && experience[:start_date].match?(date_format_regex)
          experience[:end_date] = "#{experience[:end_date]}-01" if experience[:end_date].present? && experience[:end_date].match?(date_format_regex)
        end
      end
      if whitelisted[:educations_attributes]
        whitelisted[:educations_attributes].each do |_key, experience|
          experience[:start_date] = "#{experience[:start_date]}-01" if experience[:start_date].present? && experience[:start_date].match?(date_format_regex)
          experience[:end_date] = "#{experience[:end_date]}-01" if experience[:end_date].present? && experience[:end_date].match?(date_format_regex)
        end
      end
    end
  end

end
