class Admin::ReportsController < ApplicationController
  http_basic_authenticate_with name: "admin", password: "wangwang"

  def weekly_growth
    # 确定查询的起始日期
    start_date = User.minimum(:created_at)&.at_beginning_of_week || Time.zone.now.beginning_of_week
    end_date = Time.current.at_end_of_week

    # 从数据库中获取每周的用户注册数量
    weekly_counts = User.where(created_at: start_date..end_date)
                        .group(Arel.sql("DATE_TRUNC('week', created_at)"))
                        .order(Arel.sql("DATE_TRUNC('week', created_at)"))
                        .count

    # 格式化键并转换为日期对象
    formatted_weekly_counts = weekly_counts.transform_keys { |date| date.to_date }

    # 初始化变量用于存储上一周的累积用户数
    cumulative_users = 0
    last_week_cumulative = 0

    # 计算每周的累积用户数并计算增长率
    @weekly_growth = (start_date.to_date..end_date.to_date).step(7).map do |date|
      week_start = date.beginning_of_week
      weekly_count = formatted_weekly_counts[week_start] || 0
      cumulative_users += weekly_count
      growth_rate = if last_week_cumulative.zero?
                      0
                    else
                      ((cumulative_users - last_week_cumulative) / last_week_cumulative.to_f * 100).round(2)
                    end
      last_week_cumulative = cumulative_users  # 更新上一周的累积用户数

      { week_start: week_start, cumulative_users: cumulative_users, weekly_users: weekly_count, growth_rate: "#{growth_rate} %" }
    end
  end
end
