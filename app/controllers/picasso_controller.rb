class PicassoController < ApplicationController
  def index
  end

  def new
  end

  def show_view
    # 获取 view 名称
    view_name = params[:view_name]

    # 检查是否存在对应的 view
    if lookup_context.exists?(view_name, "picasso/views")
      # 如果存在，渲染对应的 view
      render "picasso/views/#{view_name}"
    else
      # 如果不存在，返回 404
      render plain: "View not found", status: :not_found
    end
  end
end
