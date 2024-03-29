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

  private

  def user_params
    params.require(:user).permit(:phone_number, :password, :password_confirmation)
  end
end
