class Works::QuestionnairesController < ApplicationController
  before_action :authenticate_user

  def index
    @questionnaires = current_user.questionnaires
  end

  def new
    @questionnaire = current_user.questionnaires.build
  end

  def create
    @questionnaire = current_user.questionnaires.build(questionnaire_params)
    if @questionnaire.save
      flash[:success] = '问卷创建成功'
      redirect_to works_questionnaire_path(@questionnaire)
    else
      flash[:error] = '问卷创建失败，请重试'
      render :new
    end
  end

  def show
    @session = Session.find('3f210e80-1163-4980-939d-fcd025a8f9f0')
    @chat_histories = @session.chat_histories
  end

  def update

  end

  def chat

  end

  private

  def questionnaire_params
    params.require(:questionnaire).permit(:title, :target_user)
  end
end
