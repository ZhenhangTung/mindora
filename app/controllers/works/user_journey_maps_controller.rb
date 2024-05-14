class Works::UserJourneyMapsController < ApplicationController
  before_action :set_user_journey_map, only: [:show, :update]

  def index
    @user_journey_maps = UserJourneyMap.includes(:product).all
  end

  def new
    @user_journey_map = UserJourneyMap.new
    @user_journey_map.build_product
    @user_journey_map.prompt_forms.build
  end

  def create
    @user_journey_map = UserJourneyMap.new(user_journey_map_params)
    if @user_journey_map.save
      # TODO: flash message
      redirect_to works_user_journey_maps_path(@user_journey_map)
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

  def set_user_journey_map
    @user_journey_map = UserJourneyMap.find(params[:id])
  end
end
