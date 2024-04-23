require "test_helper"

class InterviewsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get interviews_new_url
    assert_response :success
  end

  test "should get create" do
    get interviews_create_url
    assert_response :success
  end
end
