class SettingsController < ApplicationController
  before_action :authenticate_user

  def create
    @setting = current_user.build_setting(setting_params)
    if @setting.save
      flash[:success] = "保存成功！"
      redirect_to edit_settings_path
    else
      Rails.logger.error "Failed to create user id #{current_user.id} settings: #{@setting.errors.full_messages.join(', ')}"
      flash.now[:error] = "保存失败，请重试。"
      render :edit
    end
  end

  def edit
    @setting = current_user.setting || current_user.build_setting
  end

  def update
    @setting = current_user.setting || current_user.build_setting
    if @setting.update(setting_params)
      flash[:success] = "保存成功！"
      redirect_to edit_settings_path
    else
      Rails.logger.error "Failed to update user id #{current_user.id} settings: #{@setting.errors.full_messages.join(', ')}"
      flash.now[:error] = "保存失败，请重试。"
      render :edit
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:nickname)
  end
end
