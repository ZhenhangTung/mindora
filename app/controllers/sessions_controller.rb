class SessionsController < ApplicationController
  def new
  end

  # POST /login
  def create
    user = User.find_by(phone_number: params[:phone_number])
    if user&.authenticate(params[:password])
      # Log the user in and redirect to the user's show page
      log_in user  # `log_in` is a helper method you'll need to create in sessions_helper.rb
      # flash[:success] = "你已经成功登录！" # TODO: display a flash message
      Rails.logger.info "User #{user.id} logged in at #{Time.current}"
      redirect_to root_path(user)
    else
      # Create an error message
      flash[:warning] = '手机号或者密码错误' # Not quite right!
      Rails.logger.warn "Failed login attempt for phone number: #{params[:phone_number]}"
      redirect_to new_session_path
    end
  end

  # DELETE /logout
  def destroy
    Rails.logger.info "User #{current_user.id} logged out at #{Time.current}" if logged_in?
    log_out if logged_in?  # `log_out` and `logged_in?` are helper methods to be defined in sessions_helper.rb
    # flash[:success] = "你已经成功退出！" # TODO: display a flash message
    redirect_to root_url
  end
end
