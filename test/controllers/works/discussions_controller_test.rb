require "test_helper"

class Works::DiscussionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get works_discussions_index_url
    assert_response :success
  end

  test "should get create" do
    get works_discussions_create_url
    assert_response :success
  end
end
