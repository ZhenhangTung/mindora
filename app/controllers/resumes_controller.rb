class ResumesController < ApplicationController
  # extract_resume_content_prompt = Langchain::Prompt::PromptTemplate.new(
  #   template: "Tell me a {adjective} joke about {content}.",
  #   input_variables: ["adjective", "content"]
  # )

  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)
    if @resume.save
      file_content = read_uploaded_file_content(@resume.original_file)
      json_data = extract_resume_from_file(file_content)
      pp '-------json_data------'
      pp json_data

      # Call the model method to update the resume with extracted data
      @resume.update_with_extracted_data(json_data)


      flash[:success] = '简历上传成功！'
      # TODO: implement me
      # https://tailwindui.com/components/application-ui/feedback/alerts
      redirect_to @resume
    else
      render :new
    end
  rescue => e
    flash.now[:error] = "An error occurred: #{e.message}"
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

  end

  def show
    @resume = Resume.find(params[:id])
  end

  def extract_resume_from_file(file_content)
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
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
                        "description": "All content under this position."
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

  private

  def resume_params
    params.require(:resume).permit(:original_file)
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
