require "test_helper"

class Works::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get works_products_edit_url
    assert_response :success
  end

  test "should get update" do
    get works_products_update_url
    assert_response :success
  end
end
