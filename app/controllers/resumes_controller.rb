class ResumesController < ApplicationController
  before_action :set_resume, only: [:show, :update, :customize]
  before_action :authenticate_user, only: :index

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
        ActiveRecord::Base.transaction do
          uploaded_file = resume_params[:original_file]
          file_content = read_uploaded_file_content(uploaded_file)
          json_data = extract_resume_from_file(file_content)
          @resume.update_with_extracted_data(json_data)
          @resume.save!
        end

        flash[:success] = '简历上传成功！'
        redirect_to @resume
      rescue => e
        flash[:error] = "简历上传失败！错误信息: #{e.message}"
        redirect_to new_resume_path
      end
    else
      flash[:error] = '未找到上传的文件，请重试。'
      redirect_to new_resume_path
    end
  end

  def update
    puts 'Before update:', params.inspect
    modified_params = adjust_date_params(resume_params)
    if @resume.update(modified_params)
      puts 'After update:', @resume.work_experiences.inspect
      redirect_to @resume, notice: 'Resume was successfully updated.'
    else
      redirect_to @resume, notice: 'Resume was failed to update.'
    end
  end

  def show
    @current_step = 'show_resume'
  end

  def customize
    @current_step = 'customize_resume'
    render 'show'
  end

  def extract_resume_from_file(file_content)
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: gpt_model,
        temperature: 0.1,
        messages: [
          {
            "role": "system",
            "content": "请处理以下简历，将信息提取并分类为两个主要部分：工作经历和项目经历。对于工作经历，准确识别职位、公司、开始和结束日期，并描述任何具体的项目经历，确保使用项目符号清晰地格式化这些描述。对于项目经历，准确识别项目名称、开始和结束日期，并描述任何具体的项目经历，确保使用项目符号清晰地格式化这些描述。至关重要的是，尤其对于个人信息、教育、工作经历、项目经历等部分，必须逐字捕获所有细节。根据提供的JSON模式结构化输出，确保每一条信息的完整性和精确性，准确地将它们放置在JSON模式的相应字段中。如果任何细节与模式不完全对应，或者出现歧义，请清楚地标记这些实例以供人工审查，而不是省略或总结。目标是在将原始信息组织成提供的结构化JSON格式的同时，保持原始信息的完整性，确保详尽地提取每个模式键的具体信息，不遗漏任何细节。",
          },
          {
            "role": "user",
            "content": "Task: I have a resume document that I would like to extract information from and fill out the JSON schema.
Document: #{file_content}",
          },
        ],
        functions: [
          {
            name: "extract_resume_content",
            description: "Extract information from a resume and fill out the JSON schema",
            parameters: {
              type: :object,
              properties: {
                name: { type: :string },
                gender: {
                  type: :string,
                  enum: ["女", "男"],
                },
                phone_number: { type: :string },
                email: { type: :string },
                work_experiences: {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "position": {
                        "type": "string",
                        "description": "从工作经历中提取的职位名称"
                      },
                      "company": {
                        "type": "string",
                        "description": "从工作经历中提取的公司名称"
                      },
                      "start_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The start date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "end_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The end date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "project_experience": {
                        "type": "string",
                        "description": "Extract the project experiences listed under each work experience from the resume, and present them using bullet points (•) for clear distinction. "
                      },
                      "experience_type": {
                        "type": "string",
                        "description": "The type of experience, either 'work' or 'project'. 如果是工作经历将它定义为'work'，如果是项目经历将它定义为'project'。"
                      }
                    },
                    "required": ["position", "company", "start_date", "end_date", "project_experience", "experience_type"]
                  }
                },
                project_experiences: {
                  "type": "array",
                  "description": "项目经历或者项目经验部分下的多条内容",
                  "items": {
                    "type": "object",
                    "properties": {
                      "start_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The start date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "end_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The end date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "project_experience": {
                        "type": "string",
                        "description": "详细描述项目经历，使用项目符号（•）进行清晰区分 "
                      },
                      "experience_type": {
                        "type": "string",
                        "description": "经历类型，'work'表示工作经历，'project'表示项目经历。"
                      },
                      "project_name": {
                        "type": "string",
                        "description": "项目名称"
                      }
                    },
                    "required": ["start_date", "end_date", "project_experience", "experience_type"]
                  }
                },
                educations: {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "school": { "type": "string" },
                      "major": { "type": "string" },
                      "start_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The start date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "end_date": {
                        "type": "string",
                        "format": "date",
                        "description": "The end date in yyyy-mm-dd format (e.g. 2023-02-13)"
                      },
                      "degree": { "type": "string" }
                    },
                    "required": ["school", "major", "start_date", "end_date", "degree"]
                  }
                },
              },
              required: ["name", "gender", "phone_number", "email", "work_experiences", "educations"],
            },
          },
        ]
      }
    )

    message = response.dig("choices", 0, "message")
    resume = {}
    if message["role"] == "assistant" && message["function_call"]
      function_name = message.dig("function_call", "name")
      args =
        JSON.parse(
          message.dig("function_call", "arguments"),
          { symbolize_names: true },
          )

      case function_name
      when "extract_resume_content"
        resume = extract_resume_content(**args)
      end
    end
    resume
  end

  def extract_resume_content(content)
    # Parse the JSON data into a Ruby hash, if not already done
    resume_data = content.is_a?(String) ? JSON.parse(content, symbolize_names: true) : content
     content

    # Ensure work experiences are processed for date formatting and any other adjustments
    processed_work_experiences = resume_data[:work_experiences]&.map do |we_data|
      process_experience_dates(we_data)
    end || []



    # Combine project experiences into work experiences if project experiences are present
    if resume_data[:project_experiences]
      processed_project_experiences = resume_data[:project_experiences].map do |project_experience|
        process_project_experience(project_experience)
      end
      # Combine work experiences and project experiences
      combined_experiences = processed_work_experiences + processed_project_experiences
      resume_data[:work_experiences] = combined_experiences
    else
      resume_data[:work_experiences] = processed_work_experiences
    end

    resume_data
  end

  def read_uploaded_file_content(uploaded_file)
    # Check if the file exists and is not nil
    if uploaded_file.present?
      case File.extname(uploaded_file.original_filename).downcase
      when ".docx"
        read_docx_content(uploaded_file)
      when ".pdf"
        read_pdf_content(uploaded_file)
      else
        "Unsupported file type"
      end
    end
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
        model: gpt_model,
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
        model: gpt_model,
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
        model: gpt_model,
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "根据以下职位要求的关键元素和权重，从提供的工作经历中提取相关性最高的 3 项匹配项，要求每一项不超过 70 字：
- 职位要求关键元素与权重：[职位要求关键词1]:[权重], [职位要求关键词2]:[权重], ...
- 提供的工作经历：[工作经历1描述], [工作经历2描述], ...
如果某项要求没有直接匹配的经历，请使用占位符“[请提供相关经验或技能]”提示用户补充。

请按照以下格式提供匹配结果：
• [匹配的关键词]： [相关的工作经历部分/数据支持/成就。如果无匹配，使用占位符。]
• [匹配的关键词]： [相关的工作经历部分/数据支持/成就。如果无匹配，使用占位符。]"
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
    @resume = Resume.find(params[:id])
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

  def read_docx_content(uploaded_file)
    # Process DOCX file
    Docx::Document.open(uploaded_file.path) do |doc|
      doc.paragraphs.map(&:text).join("\n") # Assuming you want to return the text as a string
    end
  rescue StandardError => e
    "Failed to read .docx file: #{e.message}"
  end

  def read_pdf_content(uploaded_file)
    # Process PDF file
    PDF::Reader.new(uploaded_file.path).pages.map(&:text).join("\n")
  rescue PDF::Reader::MalformedPDFError => e
    "Failed to read .pdf file: #{e.message}"
  rescue StandardError => e
    "Failed to read .pdf file: #{e.message}"
  end

  def authenticate_user
    redirect_to login_path unless current_user
  end


  def process_experience_dates(experience)
    # Handle "至今" for end_date
    experience[:end_date] = nil if experience[:end_date] == "至今"

    # Convert start_date and end_date from String to Date
    begin
      experience[:start_date] = Date.parse("#{experience[:start_date]}-01").strftime("%Y-%m") if experience[:start_date]&.match(/\A\d{4}-\d{2}\z/)
      experience[:end_date] = Date.parse(experience[:end_date]).strftime("%Y-%m") unless experience[:end_date].nil?
    rescue ArgumentError
      experience[:end_date] = nil # Handle parsing error for end_date
    end

    experience
  end

  def process_project_experience(project_experience)
    experience_entry = {
      position: "", # No position info, set as empty or handle accordingly
      company: "", # No company info, set as empty or handle accordingly
      start_date: project_experience[:start_date],
      end_date: project_experience[:end_date],
      project_experience: project_experience[:project_experience],
      experience_type: project_experience[:experience_type], # 'project'
      project_name: project_experience[:project_name]
    }

    # Process dates for project experience
    process_experience_dates(experience_entry)
  end

  def gpt_model
    Rails.env.development? ? "gpt-3.5-turbo" : "gpt-4-turbo-preview"
  end

end
