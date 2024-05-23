# frozen_string_literal: true

class ProcessResumeJob < ApplicationJob
  include GptHelper

  queue_as :resume

  def perform(resume_id)
    resume = Resume.find(resume_id)
    return unless resume
    broadcast_status(resume_id, Resume::STATUS_PROCESSING, "简历正在处理中...")
    begin
      ActiveRecord::Base.transaction do
        uploaded_file = resume.original_file
        file_content = read_resume_file_content(uploaded_file)
        Rails.logger.debug "Resume file content for user #{resume.user.id}: #{file_content}"
        json_data = extract_resume_from_file(file_content)
        resume.update_with_extracted_data(json_data)
        resume.save!
      end
      resume.save_processing_status(Resume::STATUS_COMPLETED)
      broadcast_status(resume_id, Resume::STATUS_COMPLETED, "简历处理完成！")
    rescue => e
      # Log error with detailed information
      Rails.logger.error "Resume processing failed for user #{resume.user.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      resume.save_processing_status(Resume::STATUS_FAILED)
      broadcast_status(resume_id, Resume::STATUS_FAILED, "简历处理失败: #{e.message}")
      resume.destroy
    end
  end


  private

  def read_resume_file_content(uploaded_file)
    # Check if the file exists and is not nil
    if uploaded_file.attached?
      case uploaded_file.blob.filename.extension.downcase
      # when "docx"
      #   read_docx_resume(uploaded_file)
      when "pdf"
        read_pdf_resume(uploaded_file)
      else
        "Unsupported file type"
      end
    end
  end

  def read_pdf_resume(uploaded_file)
    # Download the file and read its content
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(uploaded_file.download)
    tempfile.rewind

    PDF::Reader.new(tempfile.path).pages.map(&:text).join("\n")
  rescue PDF::Reader::MalformedPDFError => e
    Rails.logger.error "Failed to read .pdf file: #{e.message}"
    "Failed to read .pdf file: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Failed to read .pdf file: #{e.message}"
    "Failed to read .pdf file: #{e.message}"
  ensure
    tempfile.close
    tempfile.unlink
  end

  # TODO: implement me later
  # def read_docx_resume(uploaded_file)
  #   # Download the file and read its content
  #   tempfile = Tempfile.new
  #   tempfile.binmode
  #   tempfile.write(uploaded_file.download)
  #   tempfile.rewind
  #
  #   Docx::Document.open(tempfile.path) do |doc|
  #     doc.paragraphs.map(&:text).join("\n")
  #   end
  # rescue StandardError => e
  #   Rails.logger.error "Failed to read .docx file: #{e.message}"
  #   "Failed to read .docx file: #{e.message}"
  # ensure
  #   tempfile.close
  #   tempfile.unlink
  # end

  def extract_resume_from_file(file_content)
    # improve me
    client = OpenAI::Client.new(
      request_timeout: 60,
      uri_base: gpt4o_deployment_uri,
      access_token: ENV["AZURE_EASTUS2_OPENAI_API_KEY"]
      )
    response = client.chat(
      parameters: {
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

  def broadcast_status(resume_id, status, message)
    ActionCable.server.broadcast(
      "resume_status_channel_#{resume_id}",
      { status: status, message: message }
    )
  end
end
