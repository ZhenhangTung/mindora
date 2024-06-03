class Works::ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update]

  def index
    @products = current_user.products
  end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)
    if @product.save
      flash[:success] = '产品创建成功'
      redirect_to works_products_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    @user_journey_map = UserJourneyMap.find(params[:user_journey_map_id])
    
    if @product.update(product_params)
      # TODO: flash message
      redirect_to works_user_journey_map_path(@user_journey_map)
    else
      redirect_to works_user_journey_map_path(@user_journey_map)
    end
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:description, :target_user)
  end
end
