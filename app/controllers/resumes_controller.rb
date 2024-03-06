class ResumesController < ApplicationController
  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)
    if @resume.save
      # file_content = read_uploaded_file_content(@resume.original_file)
      # pp file_content

      @resume.original_file.download do |tempfile|
        puts '///////'
        puts tempfile.class # Should output "Tempfile" or similar IO object class
        # Use tempfile here...
      end

      flash[:success] = '简历上传成功！'
      # https://tailwindui.com/components/application-ui/feedback/alerts
      # redirect_to @resume
    else
      render :new
    end
  #   @resume.user = current_user # Assuming you have a method to identify the current user

    # if @resume.save
    #   flash[:success] = "Resume uploaded successfully."
    #   redirect_to @resume
    # else
    #   flash.now[:error] = "There was a problem with your upload."
    #   render :new
    # end
  end

  def show
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
    attachment.download do |file_path|
      doc = Docx::Document.open(file_path)
      content = doc.paragraphs.map(&:to_s).join("\n") # Join paragraphs with newline characters
    end
    content
  rescue StandardError => e
    "Failed to read .docx file: #{e.message}"
  end

  def read_pdf_content(attachment)
    content = "" # Initialize an empty string to hold the extracted content

    if attachment.attached?
      attachment.download do |downloaded_file|
        puts "Downloaded file class: #{downloaded_file.class}"
        # Expected to be Tempfile or similar IO object, not String
      end
    end
    # attachment.download do |file_path|
    #   pp '-----'
    #   pp "Tempfile class: #{file_path.class}"
    #
    #   # Make sure to rewind the tempfile in case it's been read before
    #   # tempfile.rewind
    #
    #   # reader = PDF::Reader.new(tempfile) # Initialize the PDF reader with the IO object
    #   # # Extract text from each page and concatenate it into the content string
    #   # content = reader.pages.map(&:text).join("\n")
    # end
    content # Return the concatenated text content
  # rescue PDF::Reader::MalformedPDFError => e
  #   "Failed to read PDF file: #{e.message}" # Handle specific PDF reader errors
  # rescue StandardError => e
  #   "An error occurred while reading the PDF file: #{e.message}" # Handle other potential errors
  end

end
