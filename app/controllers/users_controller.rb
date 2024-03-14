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
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:phone_number, :password, :password_confirmation)
  end
end
