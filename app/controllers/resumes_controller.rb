class ResumesController < ApplicationController
  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)

    if @resume.save
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

  private

  def resume_params
    params.require(:resume).permit(:original_file)
  end
end
