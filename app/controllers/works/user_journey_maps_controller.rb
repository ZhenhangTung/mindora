class Works::UserJourneyMapsController < ApplicationController
  def index
  end

  def new
    @user_journey_map = UserJourneyMap.new
    @user_journey_map.build_product
    @user_journey_map.prompt_forms.build
  end

  def create
    # pp user_journey_map_params

    @user_journey_map = UserJourneyMap.new(user_journey_map_params)
    pp @user_journey_map.product
    pp @user_journey_map.prompt_forms

    if @user_journey_map.save
      redirect_to works_user_journey_maps_path, notice: 'User Journey Map was successfully created.'
    else
      render :new
    end
  end

  def show
  end

  def update

  end

  private

  def user_journey_map_params
    params.require(:user_journey_map).permit(
      product_attributes: [:description, :target_user],
      prompt_forms_attributes: [:ideas, :challenges]
    )
  end
end
