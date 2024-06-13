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
    get_weather
    # params = questionnaire_params
    # @questionnaire = current_user.questionnaires.build(params)
    # if @questionnaire.save
    #   @questionnaire.create_session
    #   questions = generate_questions(params[:title], params[:target_user])
    #
    #   flash[:success] = '问卷创建成功'
    #   redirect_to works_questionnaire_path(@questionnaire)
    # else
    #   flash[:error] = '问卷创建失败，请重试'
    #   render :new
    # end
  end

  def edit
    @session = @questionnaire.session
    @chat_histories = @session.chat_histories
  end

  def update
    if @questionnaire.update(questionnaire_params)
    else
      render :show
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

  def generate_questions(title, target_user)
    client = OpenAI::Client.new

    system_prompt = PromptManager.get_system_prompt(:default)

    prompt_params = {
      main_purpose: title,
      target_user: target_user
    }
    prompt = PromptManager.get_template_prompt(:questionnaire, prompt_params)


    response = client.chat(
      parameters: {
        temperature: 0.7,
        messages: [
          {
            "role": "system",
            "content": system_prompt
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
        functions: [
          {
            name: "get_questions",
            description: "提取问题列表并且将其组成一个 JSON 数组",
            parameters: {
              type: :object,
              properties: {
                questions: {
                  type: :array,
                  items: {
                    type: :string,
                    description: "用户调研的问题",
                  },
                }
              },
              required: ["questions"],
            }
          }
        ]
      }
    )
    message = response.dig("choices", 0, "message")
    pp '00000'
    pp message
    questions = []
    if message["role"] == "assistant" && message["function_call"]
      function_name = message.dig("function_call", "name")
      args =
        JSON.parse(
          message.dig("function_call", "arguments"),
          { symbolize_names: true },
          )

      case function_name
      when "get_questions"
        questions = get_questions(**args)
      end
    end
    questions
  end

  def get_questions(questions)
    pp "===="
    pp questions
    questions
  end


  def get_current_weather(location:, unit: "fahrenheit")
    # Here you could use a weather api to fetch the weather.
    "The weather in #{location} is nice 🌞 #{unit}"
  end

  def get_weather
    client = OpenAI::Client.new do |f|
      f.response :logger, Logger.new($stdout), bodies: true
    end

    messages = [
      {
        "role": "user",
        "content": "What is the weather like in San Francisco?",
      },
    ]
    response =
      client.chat(
        parameters: {
          messages: messages,  # Defined above because we'll use it again
          tools: [
            {
              type: "function",
              function: {
                name: "get_current_weather",
                description: "Get the current weather in a given location",
                parameters: {  # Format: https://json-schema.org/understanding-json-schema
                               type: :object,
                               properties: {
                                 location: {
                                   type: :string,
                                   description: "The city and state, e.g. San Francisco, CA",
                                 },
                                 unit: {
                                   type: "string",
                                   enum: %w[celsius fahrenheit],
                                 },
                               },
                               required: ["location"],
                },
              },
            }
          ],
          tool_choice: {"type": "function", "function": {"name": "get_current_weather"}}
          # Optional, defaults to "auto"
          # Can also put "none" or specific functions, see docs
        },
        )
    # https://github.com/Azure-Samples/openai/blob/main/Basic_Samples/Functions/working_with_functions.ipynb
    # TODO: https://community.openai.com/t/new-tool-choice-as-required-is-not-available-on-azure/740735

    message = response.dig("choices", 0, "message")

    if message["role"] == "assistant" && message["tool_calls"]
      message["tool_calls"].each do |tool_call|
        tool_call_id = tool_call.dig("id")
        function_name = tool_call.dig("function", "name")
        function_args = JSON.parse(
          tool_call.dig("function", "arguments"),
          { symbolize_names: true },
          )
        function_response = case function_name
                            when "get_current_weather"
                              get_current_weather(**function_args)  # => "The weather is nice 🌞"
                            else
                              # decide how to handle
                            end

        # For a subsequent message with the role "tool", OpenAI requires the preceding message to have a tool_calls argument.
        messages << message

        messages << {
          tool_call_id: tool_call_id,
          role: "tool",
          name: function_name,
          content: function_response
        }  # Extend the conversation with the results of the functions
      end

      second_response = client.chat(
        parameters: {
          messages: messages
        })

      pp '------'
      pp second_response.dig("choices", 0, "message", "content")

      # At this point, the model has decided to call functions, you've called the functions
      # and provided the response back, and the model has considered this and responded.
    end
  end
end
