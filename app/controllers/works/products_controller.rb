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
    if @product.update(product_params)
      flash[:success] = '更新成功！'
      redirect_to edit_works_product_path(@product)
    else
      flash[:error] = '更新失败，请重试'
      render :edit
    end
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :target_user)
  end
end
