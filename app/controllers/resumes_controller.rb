class ResumesController < ApplicationController
  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)
    if @resume.save
      file_content = read_uploaded_file_content(@resume.original_file)
      pp file_content

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
