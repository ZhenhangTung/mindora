class Admin::ReportsController < ApplicationController
  http_basic_authenticate_with name: "admin", password: "wangwang"

  def weekly_growth
    # 确定查询的起始日期
    start_date = User.minimum(:created_at)&.at_beginning_of_week || Time.zone.now.beginning_of_week
    end_date = Time.current.at_end_of_week

    # 从数据库中获取数据
    weekly_data = User.where(created_at: start_date..end_date)
                      .group(Arel.sql("DATE_TRUNC('week', created_at)"))
                      .order(Arel.sql("DATE_TRUNC('week', created_at)"))
                      .count

    # 确保所有周都有数据
    @weekly_growth = (start_date.to_date..end_date.to_date).step(7).map do |date|
      week_start = date.beginning_of_week
      [week_start, weekly_data[week_start] || 0]
    end
  end
end
