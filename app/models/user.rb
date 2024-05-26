class User < ApplicationRecord
  has_secure_password
  has_many :resumes, dependent: :destroy
  has_many :products, dependent: :destroy

  def self.weekly_growth_report
    weekly_users = User.group("DATE_TRUNC('week', created_at)").count
    last_count = nil

    weekly_users.map do |week, count|
      growth_rate = last_count ? ((count - last_count) / last_count.to_f * 100).round(2) : nil
      last_count = count

      {
        week: week,
        users_count: count,
        growth_rate: growth_rate
      }
    end
  end
end
