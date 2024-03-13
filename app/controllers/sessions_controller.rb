class SessionsController < ApplicationController
  def new
  end

  # POST /login
  def create
    user = User.find_by(phone_number: params[:phone_number])
    if user&.authenticate(params[:password])
      # Log the user in and redirect to the user's show page
      log_in user  # `log_in` is a helper method you'll need to create in sessions_helper.rb
      flash[:success] = "你已经成功登录！"
      redirect_to root_path(user)
    else
      # Create an error message
      flash[:warning] = '手机号或者密码错误' # Not quite right!
      redirect_to new_session_path
      # FIXME: Using turbo_stream to render flash message
      # flash.now[:warning] = "Invalid phone number or password"
      # respond_to do |format|
      #   format.turbo_stream {
      #     render turbo_stream: turbo_stream.update('flash-messages', partial: 'layout/flash_message', locals: { warning: 'Invalid phone number or password' })
      #   }
      #   format.html { render :new, status: :unprocessable_entity }
      # end
    end
  end

  # DELETE /logout
  def destroy
    log_out if logged_in?  # `log_out` and `logged_in?` are helper methods to be defined in sessions_helper.rb
    flash[:success] = "你已经成功退出！"
    redirect_to root_url
  end
end
