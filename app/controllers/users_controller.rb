class UsersController < ApplicationController
  def new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Log the user in and redirect to the user's page
      session[:user_id] = @user.id
      flash[:success] = "你的账户已经成功创建！"
      redirect_to "/", notice: "Registration successful!"
    else
      Rails.logger.error "User creation failed: " + user.errors.full_messages.to_sentence
      flash[:error] = "注册失败，请检查输入是否正确，或者联系汪汪管理员。"
      render :new
    end
  end

  def reset_password_form

  end

  def reset_password
    @user = User.find_by(phone_number: reset_password_params[:phone_number])
    if @user&.update(reset_password_params)
      flash[:success] = "密码已成功重置。"
      redirect_to login_path
    else
      flash[:error] = "无法重置密码，请确认手机号是否正确。"
      render :reset_password_form
    end
  end

  private

  def user_params
    params.require(:user).permit(:phone_number, :password, :password_confirmation)
  end

  def reset_password_params
    params.permit(:phone_number, :password, :password_confirmation)
  end
end
