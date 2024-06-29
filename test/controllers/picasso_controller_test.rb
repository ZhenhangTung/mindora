require "test_helper"

class PicassoControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get picasso_index_url
    assert_response :success
  end
end
