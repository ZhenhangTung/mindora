class ResumesController < ApplicationController
  before_action :set_resume, only: [:show, :update]

  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)
    if @resume.save
      file_content = read_uploaded_file_content(@resume.original_file)
      json_data = extract_resume_from_file(file_content)

      pp json_data

      # Call the model method to update the resume with extracted data
      @resume.update_with_extracted_data(json_data)


      flash[:success] = '简历上传成功！'
      # TODO: implement me
      # https://tailwindui.com/components/application-ui/feedback/alerts
      redirect_to @resume
    else
      flash[:fail] = '简历上传失败！'
      render :new
    end
  rescue => e
    pp 'errrrr'
    pp e
    flash[:fail] = "An error occurred: #{e.message}"
    render :new
  #   @resume.user = current_user # Assuming you have a method to identify the current user

    # if @resume.save
    #   flash[:success] = "Resume uploaded successfully."
    #   redirect_to @resume
    # else
    #   flash.now[:error] = "There was a problem with your upload."
    #   render :new
    # end
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

  end

  def extract_resume_from_file(file_content)
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        temperature: 0.1,
        messages: [
          {
            "role": "system",
            "content": "Carefully analyze the provided resume document to extract detailed information without missing any specifics for each schema key. It is crucial to avoid summarizing details; instead, capture the information verbatim,especially for sections like Personal Information, Education, Work Experience, Skills, Certifications, Publications, and References. Ensure that every piece of information is accurately placed into the corresponding field within the JSON schema below. If the data doesn't fit exactly or if any details are ambiguous, please mark these instances clearly for manual review rather than omitting or summarizing. The objective is to maintain the integrity of the original information while organizing it into the structured JSON format provided, ensuring completeness and precision in every key.",
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
                      "position": { "type": "string" },
                      "company": { "type": "string" },
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
                      }
                    },
                    "required": ["position", "company", "start_date", "end_date", "project_experience"]
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
     content
  end

  # Assuming `original_file` is a method/attribute of `@resume`
  def read_uploaded_file_content(attachment)
    if attachment.attached?
      case File.extname(attachment.filename.to_s).downcase
      when ".docx"
        read_docx_content(attachment)
      when ".pdf"
        read_pdf_content(attachment)
      else
        "Unsupported file type"
      end
    end
  end


  def optimize
    original_text = params[:project_experience]
    optimized_text = optimize_with_chatgpt(original_text)
    render json: { optimized_text: optimized_text }
  end

  def optimize_with_chatgpt(original_text)
    prompt = "以下是针对产品经理简历中几段工作经历的修改：

修改前：
基于招商引资的场景，上线招商资源和政策的智能问答AI助手，目前已在河源开放测试入口，日均有效Query数近300条，整体正确率86%。工作内容如下：
1、场景探索：综合考虑业务场景、用户需求和大模型技术特点，最终确定以”载体资源匹配“和”招商政策解读“作为切入点；
2、知识库和测试集构建：基于业务目标和用户场景，协调运营资源对知识库数据进行处理，构建知识库，并负责从0到1定义测试集，确定评分标准；
3、模型评测与调优：基于测试集，对模型效果进行全面评测，并梳理可调优的关键点，与研发同学沟通，优化内部知识库产品回答效果；
4、产品功能设计：设计问答功能页面、点赞点踩功能等，并推动实现与招商引资搜索功能的整合，日均有效query数提升30%；
5、最佳解决方案探索：除内部基于LangChain框架探索本地知识库实现方案以外，还负责尝试以下路径，寻找最佳解决方案；
与AI厂商深度合作：尝试与其他AI厂商合作。负责对接各家AI厂商，包括百度、云天励飞、南威、彩智等，沟通场景和需求，提供训练数据，并对各家的效果进行评测和对比，确定最终合作方以及合作模式；标准知识库API产品评测：评测百川等标准知识库产品，比较效果，形成结果和成本报告，供项目组参考。

修改后：
• 工作成果：基于招商引资的场景，上线招商资源和政策的智能问答AI助手，目前已在河源开放测试入口，日均有效Query数近300条，整体正确率86%。
• 用户调研：综合考虑业务场景、用户需求和大模型技术特点，最终确定以”载体资源匹配“和”招商政策解“读“作为切入点。
• 竞品分析：评测与百度等与AI厂商深度合作方案和百川等标准知识库产品，交付评测报告。
• 产品设计：设计问答功能页面、点赞点踩功能等，并推动实现与招商引资搜索功能的整合，日均有效 query数提升30%。
• 构建知识库和测试集：基于业务目标和用户场景，协调运营资源构建知识库，从0到1定义测试集并确定评分标准，最终提升评测效率50%。
• 微调模型：基于测试集，对模型效果进行全面评测并梳理可调优的关键点，与研发同学沟通，优化内部知识库产品回答效果，将准确率从50%提升至86%。

修改前：
针对各CA公司数字证书不互通、办理流程繁琐、多人协作困难等问题，搭建广东省首个互认互信的数字证书以及地市电子印章平台：
1、负责从0到1实现数字证书办理、使用、管理全流程产品功能，提供公有Saas服务或私有化部署产品能力；
2、根据高频业务场景，提供数字证书签名、签章、加解密等产品通用能力，满足上百个业务系统快速对接需求
3、已为近2万家企业签发电子印章、成功应用在10+个业务领域，业务覆盖全省21个地市，项目收入1000W+

修改后：
• 工作成果：设计并重构包括数10个外部系统的省统一行政许可审批管理系统，解决原有许可系统业务分散、数据不互通、协同困难问题，满足省局和地市上百个许可事项的个性化需求。上线后项目收入1000W+，100%替代原有业务系统的同时，还节省了30%开发工作量。
• 产品设计：完善流程引擎、表单引擎、策略引擎等低代码工具，从0到1设计行政许可申报审批管理系统产品方案，实现申请、审批、发证、管理、公示全流程低代码开发。
• 协调合作：对接数10个外部国家和省级系统，实现数据互联互通。

修改前：
原有许可系统业务分散、数据不互通、协同困难，需建立全新的省统一行政许可审批管理系统，涉及数10个外部系统的整合重构，需满足省局和地市上百个许可事项的个性化需求：
1、完善流程引擎、表单引擎、策略引擎等低代码工具，从0到1设计行政许可申报审批管理系统产品方案，实现申请、审批、发证、管理、公示全流程低代码开发，节省30%开发工作量；
2、搭建许可事项接入平台，完善通用能力，最小化开发业务个性化需求，制定许可系统的平台接入规范，实现超过100个事项的快速接入；对接数10个外部国家和省级系统，实现数据互联互通；
3、项目收入1000W+，100%替代原有业务系统.

修改后：
• 工作成果：搭建广东省首个互认互信的数字证书以及地市电子印章平台，解决各CA公司数字证书不互通、办理流程繁琐、多人协作困难等问题。已为近2万家企业签发电子印章、成功应用在10+个业务领域，业务覆盖全省21个地市，项目收入1000W+。
• 产品设计：从0到1实现数字证书办理、使用、管理全流程产品功能，提供公有SaaS服务或私有化部署产品能力。另根据高频业务场景，提供数字证书签名、签章、加解密等产品通用能力，满足上百个业务系统快速对接需求。

修改前：
#{original_text}

修改后：
"
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        temperature: 0.2,
        # max_tokens: 200,
        top_p: 0.9,
        messages: [
          {
            "role": "system",
            "content": "请根据示例生成一个修改后的工作经历。若内容中有量化的数据引用这些数据，若内容中没有可以量化的数据则插入可以提供数据的占位符，让简历撰写者填入自己的数据。"
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
    prompt = "JD 内容：
#{job_description}
简历内容：
#{resume.work_experiences.map(&:project_experience).join("\n")}

职位匹配列表案例：
• 有云原生产品设计与研发工作经验：负责研发拼多多的金丝雀发布系统。我设计了服务资源腾挪项目，完成产品需求调研、撰写产品PRD、技术架构文档，再带领团队完成研发与测试，项目上线后2个月被使用1000+次。
• 有独立完成的产品设计作品：撰写聊产品App的PRD，完成需求分析、调研16名产品经理、用户画像、流程图、原型图等一系列工作。
• 对云原生相关技术、开源社区等有一定的了解：5年Golang研发经验，贡献核心代码给5.5k个Star的项目machinery。
• 有很强的产品Owner意识：Udacity期间作为技术负责人与5个国家的市场部合作，3个月完成维护千万用户国家信息的系统。
"
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        temperature: 0.5,
        messages: [
          {
            "role": "system",
            "content": "请根据以下职位描述匹配简历中的工作经历，按权重提取与职位描述相关的工作经历，生成职位匹配列表。"
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
      work_experiences_attributes: [
        :id,
        :company,
        :position,
        :start_date,
        :end_date,
        :project_experience,
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

  def read_docx_content(attachment)
    content = ''
    attachment.blob.open do |tempfile|
      doc = Docx::Document.open(tempfile.path)
      content = doc.paragraphs.map(&:to_s).join("\n") # Join paragraphs with newline characters
    end
    content
  rescue StandardError => e
    "Failed to read .docx file: #{e.message}"
  end

  def read_pdf_content(attachment)
    content = "" # Initialize an empty string to hold the extracted content
    attachment.blob.open do |tempfile|
      reader = PDF::Reader.new(tempfile.path) # Initialize the PDF reader with the path to the temporary file
      reader.pages.each do |page|
        content += page.text + "\n" # Append the text of each page to the content variable
      end
    end
    content # Return the concatenated text content
  end

end
