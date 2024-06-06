class Works::UserJourneyMapsController < ApplicationController
  before_action :set_product
  before_action :set_user_journey_map, only: [:show, :create_prompt_form]
  before_action :authenticate_user, only: [:index, :new, :create, :show, :create_prompt_form]

  def index
    @user_journey_maps = @product.user_journey_maps
    if @user_journey_maps.exists?
      redirect_to works_product_user_journey_map_path(@product, @user_journey_maps.first)
    else
      redirect_to new_works_product_user_journey_map_path(@product)
    end
  end

  def new
    @user_journey_map = @product.user_journey_maps.build
    @user_journey_map.prompt_forms.build(type: PromptForm::UserJourneyMap.to_s)
  end

  def create
    @user_journey_map = @product.user_journey_maps.build(user_journey_map_params)
    if @user_journey_map.save
      session = @user_journey_map.create_session(sessionable: @user_journey_map)
      prompt_form = @user_journey_map.prompt_forms.first
      content = build_chat_history_content(prompt_form)
      session.store_human_message(content) if session.respond_to?(:store_human_message)

      UserJourneyMapConversationsJob.perform_later(@user_journey_map.id)
      flash[:success] = '新的产品想法分析已提交。'
      redirect_to works_product_user_journey_map_path(@product, @user_journey_map)
    else
      flash[:error] = '新产品想法分析提交失败，请重试。'
      render :new
    end
  end

  def show
    @product = @user_journey_map.product
    @prompt_form = @user_journey_map.prompt_forms.new(type: PromptForm::UserJourneyMap.to_s)
    @session = @user_journey_map.session
    @chat_histories = @session&.chat_histories&.order(:created_at) || []
  end

  def create_prompt_form
    @prompt_form = @user_journey_map.prompt_forms.new(processed_prompt_form_params)
    if @prompt_form.save
      store_human_message

      UserJourneyMapConversationsJob.perform_later(@user_journey_map.id)
      flash[:success] = '新的产品想法分析已提交。'
      redirect_to works_product_user_journey_map_path(@product, @user_journey_map)
    else
      flash[:error] = '新产品想法分析提交失败，请重试。'
      render :show
    end
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
  end

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
