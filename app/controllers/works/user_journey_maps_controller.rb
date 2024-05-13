class Works::UserJourneyMapsController < ApplicationController
  def index
  end

  def new
    @user_journey_map = UserJourneyMap.new
    @user_journey_map.build_product
    @user_journey_map.prompt_forms.build
  end

  def create

    pp 'xxxx'

  end

  def show
  end

  def update

  end
end
