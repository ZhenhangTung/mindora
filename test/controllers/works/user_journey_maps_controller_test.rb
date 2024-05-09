require "test_helper"

class Works::UserJourneyMapsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get work_user_journey_maps_index_url
    assert_response :success
  end

  test "should get new" do
    get work_user_journey_maps_new_url
    assert_response :success
  end

  test "should get show" do
    get work_user_journey_maps_show_url
    assert_response :success
  end
end
