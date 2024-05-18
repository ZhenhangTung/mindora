class Works::UserJourneyMapsController < ApplicationController
  before_action :set_user_journey_map, only: [:show, :create_prompt_form]
  before_action :authenticate_user, only: [:index, :new, :create, :show, :create_prompt_form]

  def index
    @user_journey_maps = UserJourneyMap.joins(:product).where(products: { user_id: current_user.id }).includes(:product)
  end

  def new
    @user_journey_map = UserJourneyMap.new
    @user_journey_map.build_product(user: current_user)
    @user_journey_map.prompt_forms.build(type: PromptForm::UserJourneyMap.to_s)
  end

  def create
    @user_journey_map = UserJourneyMap.new(user_journey_map_params)
    @user_journey_map.build_product unless @user_journey_map.product
    @user_journey_map.product.user = current_user
    if @user_journey_map.save
      session = @user_journey_map.create_session(sessionable: @user_journey_map)
      prompt_form = @user_journey_map.prompt_forms.first
      content = build_chat_history_content(prompt_form)
      session.store_human_message(content) if session.respond_to?(:store_human_message)

      UserJourneyMapConversationsJob.perform_later(@user_journey_map.id)
      # TODO: flash message
      redirect_to works_user_journey_map_path(@user_journey_map)
    else
      # TODO: error message
      render :new
    end
  end

  def show
    @product = @user_journey_map.product
    @prompt_form = @user_journey_map.prompt_forms.new(type: PromptForm::UserJourneyMap.to_s)
    @chat_histories = @user_journey_map.session&.chat_histories || []
  end

  def create_prompt_form
    @prompt_form = @user_journey_map.prompt_forms.new(processed_prompt_form_params)
    if @prompt_form.save
      store_human_message

      UserJourneyMapConversationsJob.perform_later(@user_journey_map.id)
      redirect_to works_user_journey_map_path(@user_journey_map), notice: '新的产品想法分析已提交。'
    else
      @product = @user_journey_map.product
      render :show
    end
  end

  private

  def user_journey_map_params
    params.require(:user_journey_map).permit(
      product_attributes: [:description, :target_user],
      prompt_forms_attributes: [
        :id, :type, :ideas, :challenges, :_destroy
      ]
    ).tap do |whitelisted|
      if whitelisted[:prompt_forms_attributes]
        whitelisted[:prompt_forms_attributes].each do |key, form_attrs|
          form_attrs.merge!(process_prompt_form_attributes(form_attrs, PromptForm::UserJourneyMap))
        end
      end
    end
  end

  def set_user_journey_map
    @user_journey_map = UserJourneyMap.find(params[:id])
  end

  def prompt_form_params
    params.require(:prompt_form_user_journey_map).permit(:ideas, :challenges)
  end

  def processed_prompt_form_params
    process_prompt_form_attributes(prompt_form_params, PromptForm::UserJourneyMap)
  end

  def process_prompt_form_attributes(attributes, type_class)
    attributes.tap do |attrs|
      attrs[:type] ||= type_class.to_s
      attrs[:content] = {
        ideas: attrs.delete(:ideas),
        challenges: attrs.delete(:challenges)
      }
    end
  end

  def store_human_message
    session = @user_journey_map.session
    return unless session

    content = build_chat_history_content(@prompt_form)
    session.store_human_message(content) if session.respond_to?(:store_human_message)
  end

  def build_chat_history_content(prompt_form)
    "产品想法：#{prompt_form.ideas}\n当下挑战：#{prompt_form.challenges}"
  end
end
