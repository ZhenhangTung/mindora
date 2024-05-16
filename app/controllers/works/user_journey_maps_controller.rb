class Works::UserJourneyMapsController < ApplicationController
  before_action :set_user_journey_map, only: [:show, :update]

  def index
    @user_journey_maps = UserJourneyMap.includes(:product).all
  end

  def new
    @user_journey_map = UserJourneyMap.new
    @user_journey_map.build_product
    @user_journey_map.prompt_forms.build(type: PromptForm::UserJourneyMap.to_s)
  end

  def create
    @user_journey_map = UserJourneyMap.new(user_journey_map_params)
    if @user_journey_map.save
      UserJourneyMapConversationsJob.perform_later(@user_journey_map.id)
      # TODO: flash message
      redirect_to works_user_journey_map_path(@user_journey_map)
    else
      render :new
    end
  end

  def show
    @user_journey_map = UserJourneyMap.find(params[:id])
    @product = @user_journey_map.product
  end

  def update

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
          form_attrs[:type] ||= PromptForm::UserJourneyMap.to_s
          form_attrs[:content] = {
            ideas: form_attrs.delete(:ideas),
            challenges: form_attrs.delete(:challenges)
          }
        end
      end
    end
  end

  def set_user_journey_map
    @user_journey_map = UserJourneyMap.find(params[:id])
  end
end
