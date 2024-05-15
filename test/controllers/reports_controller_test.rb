require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get weekly_growth" do
    get reports_weekly_growth_url
    assert_response :success
  end
end
