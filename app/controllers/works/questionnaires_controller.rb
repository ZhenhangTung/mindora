class Works::QuestionnairesController < ApplicationController
  before_action :authenticate_user
  before_action :set_questionnaire, only: [:edit, :update, :chat]

  def index
    @questionnaires = current_user.questionnaires
  end

  def new
    @questionnaire = current_user.questionnaires.build
  end

  def create
    params = questionnaire_params
    @questionnaire = current_user.questionnaires.build(params)
    if @questionnaire.save
      @questionnaire.create_session
      questions = generate_questions(params)

      questions[:questions].each do |question_content|
        @questionnaire.questions.create(content: question_content, type: Questions::ShortText.to_s)
      end

      flash[:success] = '问卷创建成功'
      redirect_to edit_works_questionnaire_path(@questionnaire)
    else
      flash[:error] = '问卷创建失败，请重试'
      render :new
    end
  end

  def edit
    @session = @questionnaire.session
    @chat_histories = @session.chat_histories
  end

  def update
    if @questionnaire.update(questionnaire_params)
      flash[:success] = '问卷更新成功'
      redirect_to edit_works_questionnaire_path(@questionnaire)
    else
      flash[:success] = '问卷更新失败'
      render :edit
    end
  end

  def chat

  end

  private

  def questionnaire_params
    params.require(:questionnaire)
          .permit(
            :title,
            :target_user,
            :questions_attributes => [:id, :_destroy, :content],
          )
  end

  def set_questionnaire
    @questionnaire = current_user.questionnaires.find(params[:id])
  end

  def generate_questions(request_params)
    client = OpenAI::Client.new do |f|
      f.response :logger, Logger.new($stdout), bodies: true
    end

    system_prompt = PromptManager.get_system_prompt(:questionnaire)

    prompt_params = {
      main_purpose: request_params[:title],
      target_user: request_params[:target_user]
    }
    prompt = PromptManager.get_template_prompt(:questionnaire, prompt_params)

    messages = [
      {
        "role": "system",
        "content": system_prompt
      },
      {
        "role": "user",
        "content": prompt
      }
    ]


    response = client.chat(
      parameters: {
        messages: messages, # Required.
        temperature: 0.7,
        tools: [
          {
            type: "function",
            function: {
              name: "questionnaire_questions",
              description: "获取用户调研问题的列表",
              parameters: {
                type: :object,
                properties: {
                  questions: {
                    type: :array,
                    description: "用户调研问题的列表",
                    items: {
                      type: :string
                    }
                  }
                },
                required: ["questions"],
              }
            }
          }
        ],
        tool_choice: {"type": "function", "function": {"name": "questionnaire_questions"}}
      })

    message = response.dig("choices", 0, "message")

    questions = []
    if message["role"] == "assistant" && message["tool_calls"]
      message["tool_calls"].each do |tool_call|
        tool_call_id = tool_call.dig("id")
        function_name = tool_call.dig("function", "name")
        function_args = JSON.parse(
          tool_call.dig("function", "arguments"),
          { symbolize_names: true },
          )
        function_response = case function_name
                            when "questionnaire_questions"
                              questions = questionnaire_questions(**function_args)
                            else
                              # decide how to handle
                            end
      end
      questions
    end
  end

  def questionnaire_questions(questions)
    questions
  end
end
